/*
 * Knowage, Open Source Business Intelligence suite
 * Copyright (C) 2016 Engineering Ingegneria Informatica S.p.A.
 *
 * Knowage is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Knowage is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package it.eng.qbe.datasource.jpa;

import java.beans.PropertyDescriptor;
import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.persistence.EntityManager;
import javax.persistence.EntityTransaction;
import javax.persistence.Query;
import javax.persistence.metamodel.Attribute;
import javax.persistence.metamodel.Attribute.PersistentAttributeType;
import javax.persistence.metamodel.EntityType;
import javax.persistence.metamodel.Metamodel;
import javax.persistence.metamodel.SingularAttribute;

import org.apache.log4j.Logger;
import org.json.JSONException;
import org.json.JSONObject;

import it.eng.qbe.datasource.IPersistenceManager;
import it.eng.qbe.datasource.jpa.audit.JPAPersistenceManagerAuditLogger;
import it.eng.qbe.datasource.jpa.audit.Operation;
import it.eng.qbe.model.structure.IModelEntity;
import it.eng.qbe.model.structure.IModelField;
import it.eng.qbe.query.CriteriaConstants;
import it.eng.qbe.query.ExpressionNode;
import it.eng.qbe.query.WhereField;
import it.eng.qbe.statement.AbstractStatement;
import it.eng.qbe.statement.IStatement;
import it.eng.qbe.statement.jpa.JPQLDataSet;
import it.eng.qbe.statement.jpa.JPQLStatement;
import it.eng.spago.error.EMFInternalError;
import it.eng.spagobi.commons.bo.UserProfile;
import it.eng.spagobi.commons.utilities.StringUtilities;
import it.eng.spagobi.engines.qbe.registry.bo.RegistryConfiguration;
import it.eng.spagobi.engines.qbe.registry.bo.RegistryConfiguration.Column;
import it.eng.spagobi.user.UserProfileManager;
import it.eng.spagobi.utilities.assertion.Assert;
import it.eng.spagobi.utilities.exceptions.SpagoBIRuntimeException;

public class JPAPersistenceManager implements IPersistenceManager {

	private JPADataSource dataSource;

	public static transient Logger logger = Logger.getLogger(JPAPersistenceManager.class);

	public static transient Logger auditlogger = Logger.getLogger("audit.query");

	public JPAPersistenceManager(JPADataSource dataSource) {
		super();
		this.dataSource = dataSource;
	}

	public JPADataSource getDataSource() {
		return dataSource;
	}

	public void setDataSource(JPADataSource dataSource) {
		this.dataSource = dataSource;
	}

	@Override
	public String getKeyColumn(JSONObject aRecord, RegistryConfiguration registryConf) {
		String toReturn = null;

		logger.debug("IN");
		EntityManager entityManager = null;
		try {
			Assert.assertNotNull(aRecord, "Input parameter [record] cannot be null");
			Assert.assertNotNull(aRecord, "Input parameter [registryConf] cannot be null");

			logger.debug("New record: " + aRecord.toString(3));
			logger.debug("Target entity: " + registryConf.getEntity());

			entityManager = dataSource.getEntityManager();
			Assert.assertNotNull(entityManager, "entityManager cannot be null");

			EntityType targetEntity = getTargetEntity(registryConf, entityManager);
			String keyAttributeName = getKeyAttributeName(targetEntity);
			logger.debug("Key attribute name is equal to " + keyAttributeName);

			toReturn = keyAttributeName;

		} catch (Throwable t) {
			logger.error(t);
			throw new SpagoBIRuntimeException("Error searching for key column", t);
		} finally {
			if (entityManager != null) {
				if (entityManager.isOpen()) {
					entityManager.close();
				}
			}
		}

		logger.debug("OUT");
		return toReturn;
	}

	private synchronized Integer getPKValue(EntityType targetEntity, String keyColumn, EntityManager entityManager) {
		logger.debug("IN");
		Integer toReturn = 0;
		String name = targetEntity.getName();

		logger.debug("SELECT max(p." + keyColumn + ") as c FROM " + targetEntity.getName() + " p");
		// logger.debug("SELECT max(p."+keyColumn+") as c FROM "+targetEntity.getName()+" p");
		Query maxQuery = entityManager.createQuery("SELECT max(p." + keyColumn + ") as c FROM " + targetEntity.getName() + " p");

		Object result = maxQuery.getSingleResult();

		if (result != null) {
			toReturn = Integer.valueOf(result.toString());
			toReturn++;
		}

		logger.debug("New PK is " + toReturn);
		logger.debug("OUT");
		return toReturn;
	}

	private synchronized Integer getPKValueFromTemplateTable(String tableName, String keyColumn, EntityManager entityManager) {
		logger.debug("IN");
		Integer toReturn = 0;

		Query maxQuery = entityManager.createQuery("SELECT max(p." + keyColumn + ") as c FROM " + tableName + " p");

		Object result = maxQuery.getSingleResult();

		if (result != null) {
			toReturn = Integer.valueOf(result.toString());
			toReturn++;
		}

		logger.debug("New PK taken from table " + tableName + " is " + toReturn);
		logger.debug("OUT");
		return toReturn;
	}

	@Override
	public Integer insertRecord(JSONObject aRecord, RegistryConfiguration registryConf, boolean autoLoadPK, String tableForPkMax, String columnForPkMax) {

		EntityTransaction entityTransaction = null;
		Integer toReturn = null;

		logger.debug("IN");
		EntityManager entityManager = null;
		try {
			Assert.assertNotNull(aRecord, "Input parameter [record] cannot be null");
			Assert.assertNotNull(aRecord, "Input parameter [registryConf] cannot be null");

			logger.debug("New record: " + aRecord.toString(3));
			logger.debug("Target entity: " + registryConf.getEntity());

			entityManager = dataSource.getEntityManager();
			Assert.assertNotNull(entityManager, "entityManager cannot be null");

			entityTransaction = entityManager.getTransaction();

			EntityType targetEntity = getTargetEntity(registryConf, entityManager);
			String keyAttributeName = getKeyAttributeName(targetEntity);
			logger.debug("Key attribute name is equal to " + keyAttributeName);
			// targetEntity.getI

			// if(autoLoadPK == true){
			// //remove key attribute
			// aRecord.remove(keyAttributeName);
			// }

			Iterator it = aRecord.keys();

			Object newObj = null;
			Class classToCreate = targetEntity.getJavaType();

			newObj = classToCreate.newInstance();
			logger.debug("Key column class is equal to [" + newObj.getClass().getName() + "]");

			while (it.hasNext()) {
				String attributeName = (String) it.next();
				logger.debug("Processing column [" + attributeName + "] ...");

				if (keyAttributeName.equals(attributeName)) {
					logger.debug("Skip column [" + attributeName + "] because it is the key of the table");
					continue;
				}
				Column column = registryConf.getColumnConfiguration(attributeName);
				List columnDepends = new ArrayList();
				if (column.getDependences() != null && !"".equals(column.getDependences())) {
					String[] dependences = column.getDependences().split(",");
					for (int i = 0; i < dependences.length; i++) {
						// get dependences informations
						Column dependenceColumn = getDependenceColumns(registryConf.getColumns(), dependences[i]);
						if (dependenceColumn != null)
							columnDepends.add(dependenceColumn);
					}
				}

				if (column.getSubEntity() != null) {
					logger.debug("Column [" + attributeName + "] is a foreign key");
					if (aRecord.get(attributeName) != null && !aRecord.get(attributeName).equals("")) {
						logger.debug("search foreign reference for value " + aRecord.get(attributeName));
						setSubEntity(targetEntity, column, newObj, attributeName, aRecord, columnDepends, entityManager);
					} else {
						// no value in column, insert null
						logger.debug("No value for " + attributeName + ": keep it null");
					}

				} else {
					logger.debug("Column [" + attributeName + "] is a normal column");
					setProperty(targetEntity, newObj, attributeName, aRecord.get(attributeName));
				}
			}

			// calculate PK
			if (true || autoLoadPK == false) {

				Integer pkValue = null;
				// check if an alternative table and column has been specified
				// to retrieve PK
				String keyColumn = getKeyColumn(aRecord, registryConf);
				if (tableForPkMax != null && columnForPkMax != null) {
					logger.debug("Retrieve PK as max+1 from table: " + tableForPkMax + " / column: " + columnForPkMax);
					pkValue = getPKValueFromTemplateTable(tableForPkMax, columnForPkMax, entityManager);
					setKeyProperty(targetEntity, newObj, keyColumn, pkValue);
				} else {
					logger.debug("calculate max value +1 for key column " + keyColumn + " in table " + targetEntity.getName());
					pkValue = getPKValue(targetEntity, keyColumn, entityManager);
					setKeyProperty(targetEntity, newObj, keyColumn, pkValue);
				}

				if (pkValue == null) {
					logger.error("could not retrieve pk ");
					throw new Exception("could not retrieve pk for table " + targetEntity.getName());
				}

				toReturn = pkValue;
			}

			if (!entityTransaction.isActive()) {
				entityTransaction.begin();
			}

			entityManager.persist(newObj);
			entityManager.flush();
			entityTransaction.commit();

			new JPAPersistenceManagerAuditLogger(this).log(Operation.INSERTION, null, aRecord, null, registryConf);

		} catch (Throwable t) {
			if (entityTransaction != null && entityTransaction.isActive()) {
				entityTransaction.rollback();
			}
			logger.error(t);
			throw new SpagoBIRuntimeException("Error saving entity", t);
		} finally {
			if (entityManager != null) {
				if (entityManager.isOpen()) {
					entityManager.close();
				}
			}
			logger.debug("OUT");
		}
		return toReturn;
	}

	@Override
	public void updateRecord(JSONObject aRecord, RegistryConfiguration registryConf) {

		EntityTransaction entityTransaction = null;

		logger.debug("IN");
		EntityManager entityManager = null;
		try {
			Assert.assertNotNull(aRecord, "Input parameter [record] cannot be null");
			Assert.assertNotNull(aRecord, "Input parameter [registryConf] cannot be null");

			logger.debug("New record: " + aRecord.toString(3));
			logger.debug("Target entity: " + registryConf.getEntity());

			entityManager = dataSource.getEntityManager();
			Assert.assertNotNull(entityManager, "entityManager cannot be null");

			entityTransaction = entityManager.getTransaction();

			EntityType targetEntity = getTargetEntity(registryConf, entityManager);
			String keyAttributeName = getKeyAttributeName(targetEntity);
			logger.debug("Key attribute name is equal to " + keyAttributeName);

			Iterator it = aRecord.keys();

			Object keyColumnValue = aRecord.get(keyAttributeName);
			logger.debug("Key of new record is equal to " + keyColumnValue);
			logger.debug("Key column java type equal to [" + targetEntity.getJavaType() + "]");
			Attribute a = targetEntity.getAttribute(keyAttributeName);
			Object obj = entityManager.find(targetEntity.getJavaType(), this.convertValue(keyColumnValue, a));
			logger.debug("Key column class is equal to [" + obj.getClass().getName() + "]");
			// object used to track old values, just before changes
			JSONObject oldRecord = new JSONObject();
			// just to count the number of changes
			int changesCounter = 0;

			while (it.hasNext()) {
				String attributeName = (String) it.next();
				logger.debug("Processing column [" + attributeName + "] ...");

				if (keyAttributeName.equals(attributeName)) {
					logger.debug("Skip column [" + attributeName + "] because it is the key of the table");
					continue;
				}
				Column column = registryConf.getColumnConfiguration(attributeName);
				if (!column.isEditable()) {
					logger.debug("Skip column [" + attributeName + "] because it is not editable");
					continue;
				}
				List columnDepends = new ArrayList();
				if (column.getDependences() != null && !"".equals(column.getDependences())) {
					String[] dependences = column.getDependences().split(",");
					for (int i = 0; i < dependences.length; i++) {
						// get dependences informations
						Column dependenceColumns = getDependenceColumns(registryConf.getColumns(), dependences[i]);
						if (dependenceColumns != null)
							columnDepends.add(dependenceColumns);
					}
				}

				// if column is info column do not update
				if (!column.isInfoColumn()) {
					if (column.getSubEntity() != null) {
						logger.debug("Column [" + attributeName + "] is a foreign key");
						boolean changed = updateSubEntity(aRecord, entityManager, targetEntity, obj, oldRecord, attributeName, column, columnDepends);
						if (changed) {
							changesCounter++;
						}
					} else {
						logger.debug("Column [" + attributeName + "] is a normal column");
						boolean changed = updateProperty(aRecord, targetEntity, obj, oldRecord, attributeName);
						if (changed) {
							changesCounter++;
						}
					}
				}
			}

			if (!entityTransaction.isActive()) {
				entityTransaction.begin();
			}

			entityManager.persist(obj);
			entityManager.flush();
			entityTransaction.commit();

			new JPAPersistenceManagerAuditLogger(this).log(Operation.UPDATE, oldRecord, aRecord, changesCounter, registryConf);

		} catch (Throwable t) {
			if (entityTransaction != null && entityTransaction.isActive()) {
				entityTransaction.rollback();
			}
			logger.error(t);
			throw new SpagoBIRuntimeException("Error saving entity", t);
		} finally {
			if (entityManager != null) {
				if (entityManager.isOpen()) {
					entityManager.close();
				}
			}
			logger.debug("OUT");
		}

	}

	/**
	 *
	 * @return true if sub-entity was changed, false otherwise
	 * @throws JSONException
	 */
	protected boolean updateSubEntity(JSONObject aRecord, EntityManager entityManager, EntityType targetEntity, Object obj, JSONObject oldRecord,
			String attributeName, Column column, List columnDepends) throws JSONException {
		EntityType subEntityType = getSubEntityType(targetEntity, column.getSubEntity(), entityManager);
		Object subEntity = getOldSubEntity(targetEntity, column, obj);
		Object oldValue = getOldProperty(subEntityType, subEntity, attributeName);
		oldRecord.put(attributeName, oldValue);
		Object newValue = aRecord.get(attributeName);
		setSubEntity(targetEntity, column, obj, attributeName, aRecord, columnDepends, entityManager);
		if (!areEquals(oldValue, newValue)) {
			return true;
		}
		return false;
	}

	/**
	 *
	 * @return true if property was changed, false otherwise
	 * @throws JSONException
	 */
	protected boolean updateProperty(JSONObject aRecord, EntityType targetEntity, Object obj, JSONObject oldRecord, String attributeName) throws JSONException {
		Object oldValue = getOldProperty(targetEntity, obj, attributeName);
		oldRecord.put(attributeName, oldValue);
		Object newValue = aRecord.get(attributeName);
		setProperty(targetEntity, obj, attributeName, newValue);
		if (!areEquals(oldValue, newValue)) {
			return true;
		}
		return false;
	}

	private EntityType getSubEntityType(EntityType targetEntity, String subEntity, EntityManager entityManager) {
		Attribute a = targetEntity.getAttribute(subEntity);
		Attribute.PersistentAttributeType type = a.getPersistentAttributeType();
		if (type.equals(PersistentAttributeType.MANY_TO_ONE)) {
			String entityJavaSimpleName = a.getJavaType().getSimpleName();
			return getEntityByName(entityManager, entityJavaSimpleName);
		} else {
			throw new SpagoBIRuntimeException("Property " + subEntity + " is not a many-to-one relation");
		}
	}

	private Object getOldSubEntity(EntityType targetEntity, Column column, Object obj) {

		Attribute a = targetEntity.getAttribute(column.getSubEntity());

		Attribute.PersistentAttributeType type = a.getPersistentAttributeType();
		if (type.equals(PersistentAttributeType.MANY_TO_ONE)) {
			String subKey = a.getName();
			try {
				Class clazz = targetEntity.getJavaType();
				Object subEntity = new PropertyDescriptor(subKey, clazz).getReadMethod().invoke(obj);
				return subEntity;
			} catch (Exception e) {
				throw new SpagoBIRuntimeException("Error while getting sub entity " + column.getSubEntity() + " from entity " + targetEntity, e);
			}
		} else {
			throw new SpagoBIRuntimeException("Property " + column.getSubEntity() + " is not a many-to-one relation");
		}
	}

	private boolean areEquals(Object oldValue, Object newValue) {
		if (oldValue == null && newValue == null) {
			// both are null, return true
			return true;
		}
		if (oldValue == null || newValue == null) {
			// one of the 2 is null but not both
			return false;
		}
		// compare values
		return oldValue.equals(newValue);
	}

	@Override
	public void deleteRecord(JSONObject aRecord, RegistryConfiguration registryConf) {

		EntityTransaction entityTransaction = null;

		logger.debug("IN");
		EntityManager entityManager = null;
		try {
			Assert.assertNotNull(aRecord, "Input parameter [record] cannot be null");
			Assert.assertNotNull(aRecord, "Input parameter [registryConf] cannot be null");

			logger.debug("Record: " + aRecord.toString(3));
			logger.debug("Target entity: " + registryConf.getEntity());

			entityManager = dataSource.getEntityManager();
			Assert.assertNotNull(entityManager, "entityManager cannot be null");

			entityTransaction = entityManager.getTransaction();

			EntityType targetEntity = getTargetEntity(registryConf, entityManager);
			String keyAttributeName = getKeyAttributeName(targetEntity);
			logger.debug("Key attribute name is equal to " + keyAttributeName);

			Iterator it = aRecord.keys();

			Object keyColumnValue = aRecord.get(keyAttributeName);
			logger.debug("Key of record is equal to " + keyColumnValue);
			logger.debug("Key column java type equal to [" + targetEntity.getJavaType() + "]");
			Attribute a = targetEntity.getAttribute(keyAttributeName);
			Object obj = entityManager.find(targetEntity.getJavaType(), this.convertValue(keyColumnValue, a));
			logger.debug("Key column class is equal to [" + obj.getClass().getName() + "]");

			if (!entityTransaction.isActive()) {
				entityTransaction.begin();
			}

			// String q =
			// "DELETE from "+targetEntity.getName()+" o WHERE o."+keyAttributeName+"="+keyColumnValue.toString();
			String q = "DELETE from " + targetEntity.getName() + " WHERE " + keyAttributeName + "=" + keyColumnValue.toString();
			logger.debug("create Query " + q);
			Query deleteQuery = entityManager.createQuery(q);

			int deleted = deleteQuery.executeUpdate();

			// entityManager.remove(obj);
			// entityManager.flush();
			entityTransaction.commit();

			new JPAPersistenceManagerAuditLogger(this).log(Operation.DELETION, aRecord, null, null, registryConf);

		} catch (Throwable t) {
			if (entityTransaction != null && entityTransaction.isActive()) {
				entityTransaction.rollback();
			}
			logger.error(t);
			throw new SpagoBIRuntimeException("Error deleting entity", t);
		} finally {
			if (entityManager != null) {
				if (entityManager.isOpen()) {
					entityManager.close();
				}
			}
			logger.debug("OUT");
		}

	}

	public EntityType getTargetEntity(RegistryConfiguration registryConf, EntityManager entityManager) {

		String targetEntityName = getTargetEntityName(registryConf);

		EntityType targetEntity = getEntityByName(entityManager, targetEntityName);

		return targetEntity;
	}

	protected EntityType getEntityByName(EntityManager entityManager, String entityName) {
		EntityType toReturn = null;
		Metamodel classMetadata = entityManager.getMetamodel();
		Iterator it = classMetadata.getEntities().iterator();

		while (it.hasNext()) {
			EntityType entity = (EntityType) it.next();
			String jpaEntityName = entity.getName();

			if (entity != null && jpaEntityName.equals(entityName)) {
				toReturn = entity;
				break;
			}
		}
		return toReturn;
	}

	public String getKeyAttributeName(EntityType entity) {
		logger.debug("IN : entity = [" + entity + "]");
		String keyName = null;
		for (Object attribute : entity.getAttributes()) {
			if (attribute instanceof SingularAttribute) {
				SingularAttribute s = (SingularAttribute) attribute;
				logger.debug("Attribute: " + s.getName() + " is a singular attribute.");
				if (s.isId()) {
					keyName = s.getName();
					break;
				}
			} else {
				logger.debug("Attribute " + attribute + " is not singular attribute, cannot manage it");
			}
		}
		Assert.assertNotNull(keyName, "Key attribute name was not found!");
		logger.debug("OUT : " + keyName);
		return keyName;
	}

	// case of foreign key
	private void setSubEntity(EntityType targetEntity, Column c, Object obj, String aKey, JSONObject aRecord, List lstDependences,
			EntityManager entityManager) {

		logger.debug("column " + aKey + " is a FK");

		Attribute a = targetEntity.getAttribute(c.getSubEntity());

		Attribute.PersistentAttributeType type = a.getPersistentAttributeType();
		if (type.equals(PersistentAttributeType.MANY_TO_ONE)) {
			String entityJavaType = a.getJavaType().getName();
			String subKey = a.getName();
			try {
				LinkedHashMap filtersForRef = new LinkedHashMap();
				filtersForRef.put(c.getField(), (aRecord.get(aKey)));
				// add dependences if they are
				if (lstDependences != null) {
					for (int i = 0; i < lstDependences.size(); i++) {
						Column tmpDep = (Column) lstDependences.get(i);
						if (!tmpDep.isInfoColumn() && tmpDep.getSubEntity() != null)
							filtersForRef.put(tmpDep.getSubEntity() + "." + tmpDep.getField(), (aRecord.get(tmpDep.getField())));
						else if (!tmpDep.isInfoColumn() && tmpDep.getSubEntity() == null)
							filtersForRef.put(tmpDep.getField(), (aRecord.get(tmpDep.getField())));
					}
				}
				Object referenced = getReferencedObjectJPA(entityManager, entityJavaType, filtersForRef);

				Class clas = targetEntity.getJavaType();
				Field f = clas.getDeclaredField(subKey);
				f.setAccessible(true);
				// entityManager.refresh(referenced);
				f.set(obj, referenced);
			} catch (JSONException e) {
				logger.error(e);
				throw new SpagoBIRuntimeException("Property " + c.getSubEntity() + " is not a many-to-one relation", e);
			} catch (Exception e) {
				throw new SpagoBIRuntimeException("Error setting Field " + aKey + "", e);
			}
		} else {
			throw new SpagoBIRuntimeException("Property " + c.getSubEntity() + " is not a many-to-one relation");
		}
	}

	private Object getOldProperty(EntityType targetEntity, Object obj, String aKey) {

		logger.debug("IN");

		try {
			Attribute a = targetEntity.getAttribute(aKey);
			Class clazz = targetEntity.getJavaType();
			Object property = new PropertyDescriptor(aKey, clazz).getReadMethod().invoke(obj);
			return property;
		} catch (Exception e) {
			throw new SpagoBIRuntimeException("Error while getting property " + aKey + " from entity " + targetEntity, e);
		} finally {
			logger.debug("OUT");
		}
	}

	private void setProperty(EntityType targetEntity, Object obj, String aKey, Object newValue) {

		logger.debug("IN");

		try {
			Attribute a = targetEntity.getAttribute(aKey);
			Class clas = targetEntity.getJavaType();
			Field f = clas.getDeclaredField(aKey);
			f.setAccessible(true);
			Object valueConverted = this.convertValue(newValue, a);
			f.set(obj, valueConverted);
		} catch (Exception e) {
			throw new SpagoBIRuntimeException("Error setting Field " + aKey + "", e);
		} finally {
			logger.debug("OUT");
		}
	}

	private void setKeyProperty(EntityType targetEntity, Object obj, String aKey, Integer value) {

		logger.debug("IN");

		try {
			Attribute a = targetEntity.getAttribute(aKey);
			Class clas = targetEntity.getJavaType();
			Field f = clas.getDeclaredField(aKey);
			f.setAccessible(true);
			Object valueConverted = this.convertValue(value, a);
			f.set(obj, valueConverted);
		} catch (Exception e) {
			throw new SpagoBIRuntimeException("Error setting Field " + aKey + "", e);
		} finally {
			logger.debug("OUT");
		}
	}

	private String getTargetEntityName(RegistryConfiguration registryConf) {
		String entityName = registryConf.getEntity();
		int lastPkgDot = entityName.lastIndexOf(".");
		String entityNameNoPkg = entityName.substring(lastPkgDot + 1);
		return entityNameNoPkg;
	}

	private Object convertValue(Object valueObj, Attribute attribute) {
		if (valueObj == null) {
			return null;
		}
		String value = valueObj.toString();
		Object toReturn = null;

		Class clazz = attribute.getJavaType();
		String clazzName = clazz.getName();

		if (Number.class.isAssignableFrom(clazz)) {
			if (value.equals("NaN") || value.equals("null") || value.equals("")) {
				toReturn = null;
				return toReturn;
			}
			// BigInteger, Integer, Long, Short, Byte
			if (Integer.class.getName().equals(clazzName)) {
				toReturn = Integer.parseInt(value);
			} else if (Double.class.getName().equals(clazzName)) {
				toReturn = new Double(value);
			} else if (BigDecimal.class.getName().equals(clazzName)) {
				toReturn = new BigDecimal(value);
			} else if (BigInteger.class.getName().equals(clazzName)) {
				toReturn = new BigInteger(value);
			} else if (Long.class.getName().equals(clazzName)) {
				toReturn = new Long(value);
			} else if (Short.class.getName().equals(clazzName)) {
				toReturn = new Short(value);
			} else if (Byte.class.getName().equals(clazzName)) {
				toReturn = new Byte(value);
			} else {
				toReturn = new Float(value);
			}
		} else if (String.class.isAssignableFrom(clazz)) {
			if (value.equals("")) {
				toReturn = null;
			} else
				toReturn = value;
		} else if (Timestamp.class.isAssignableFrom(clazz)) {
			Date date;
			SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy hh:mm:ss");
			SimpleDateFormat sdfISO = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ");
			// SimpleDateFormat sdf = new
			// SimpleDateFormat("MM/dd/yyyy hh:mm:ss");
			if (!value.equals("") && !value.contains(":")) {
				value += " 00:00:00";
			}
			try {
				if (value.contains("Z")) {
					date = sdfISO.parse(value.replaceAll("Z$", "+0000"));
					toReturn = new Timestamp(date.getTime());
				} else {
					date = sdf.parse(value);
					toReturn = new Timestamp(date.getTime());
				}
			} catch (ParseException e) {
				logger.error("Unparsable timestamp", e);
			}

		} else if (Date.class.isAssignableFrom(clazz)) {
			// TODO manage dates
			SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

			try {
				toReturn = sdf.parse(value);
			} catch (ParseException e) {
				logger.error("Unparsable date", e);
			}

		} else if (Boolean.class.isAssignableFrom(clazz)) {
			toReturn = Boolean.parseBoolean(value);
		} else if (Clob.class.isAssignableFrom(clazz)) {
			try {
				Connection connection = dataSource.getToolsDataSource().getConnection();
				toReturn = connection.createClob();
				((Clob) toReturn).setString(1, value);
			} catch (Exception e) {
				logger.error("Error in creating clob object", e);
				toReturn = null;
			}
		} else {
			toReturn = value;
		}

		return toReturn;
	}

	private Object getReferencedObjectJPA(EntityManager em, String entityJavaType, HashMap whereFields) {

		String query = buildReferencedObjectQuery(entityJavaType, whereFields);
		logQuery(query);

		Query tmpQuery = em.createQuery(query);
		// Getting list of records...
		final List result = tmpQuery.getResultList();

		if (result == null || result.size() == 0) {
			throw new SpagoBIRuntimeException("Record with input filters [" + whereFields + "] not found for entity " + entityJavaType);
		}
		if (result.size() > 1) {
			throw new SpagoBIRuntimeException("More than 1 record with input filters [" + whereFields + "] were found in entity " + entityJavaType);
		}

		return result.get(0);
	}

	private String buildReferencedObjectQuery(String entityJavaType, HashMap whereFields) {
		it.eng.qbe.query.Query query = buildRegularQueryToReferenceObject(entityJavaType, whereFields);
		// we create a dataset object to apply profiled visibility constraints
		JPQLDataSet dataset = buildJPQLDatasetToReferenceObject(query);
		IStatement filteredStatement = dataset.getFilteredStatement();
		String jpaQueryStr = filteredStatement.getQueryString();
		/*
		 * At this point, we have a query that is like: "select t_0.id, t_0.someOtherProperty from Entity where..." that is returning an object array but we
		 * need to get a JPA object instead, therefore we are transforming the statement into "select t_0 from Entity t_0 where ..."
		 */
		jpaQueryStr = transformToEntityQuery(jpaQueryStr);
		return jpaQueryStr;
	}

	protected JPQLDataSet buildJPQLDatasetToReferenceObject(it.eng.qbe.query.Query query) {
		JPQLStatement statement = (JPQLStatement) getDataSource().createStatement(query);
		JPQLDataSet dataset = new JPQLDataSet(statement);
		// setting user profile attributes
		Map userAttributes = new HashMap();
		UserProfile profile = UserProfileManager.getProfile();
		Iterator it = profile.getUserAttributeNames().iterator();
		while (it.hasNext()) {
			String attributeName = (String) it.next();
			Object attributeValue;
			try {
				attributeValue = profile.getUserAttribute(attributeName);
			} catch (EMFInternalError e) {
				throw new SpagoBIRuntimeException("Error while getting user profile attribute [" + attributeName + "]", e);
			}
			userAttributes.put(attributeName, attributeValue);
		}
		dataset.addBinding("attributes", userAttributes);
		dataset.setUserProfileAttributes(userAttributes);
		return dataset;
	}

	protected it.eng.qbe.query.Query buildRegularQueryToReferenceObject(String entityJavaType, HashMap whereFields) {
		it.eng.qbe.query.Query query = new it.eng.qbe.query.Query();
		query.setId(StringUtilities.getRandomString(5));
		int lastPkgDotSub = entityJavaType.lastIndexOf(".");
		String entityNameNoPkgSub = entityJavaType.substring(lastPkgDotSub + 1);
		IModelEntity entity = dataSource.getModelStructure().getEntityByName(entityNameNoPkgSub);
		List<IModelField> fields = entity.getAllFields();
		for (Iterator<IModelField> it = fields.iterator(); it.hasNext();) {
			IModelField field = it.next();
			query.addSelectFiled(field.getUniqueName(), "NONE", field.getName(), true, true, false, null, null);
		}
		ArrayList<ExpressionNode> expressionNodes = new ArrayList<ExpressionNode>();
		for (Iterator iterator = whereFields.keySet().iterator(); iterator.hasNext();) {
			String key = (String) iterator.next();
			Object value = whereFields.get(key);
			if (value != null) {
				WhereField.Operand left = new WhereField.Operand(new String[] { entityJavaType + ":" + key }, "name",
						AbstractStatement.OPERAND_TYPE_SIMPLE_FIELD, null, null);
				WhereField.Operand right = new WhereField.Operand(new String[] { value.toString() }, "value", AbstractStatement.OPERAND_TYPE_STATIC, null,
						null);
				query.addWhereField(key, key, false, left, CriteriaConstants.EQUALS_TO, right, "AND");
				expressionNodes.add(new ExpressionNode("NODE_CONST", "$F{" + key + "}"));
			}
		}
		// put together expression nodes
		if (expressionNodes.size() == 1) {
			query.setWhereClauseStructure(expressionNodes.get(0));
		} else if (expressionNodes.size() > 1) {
			ExpressionNode exprNodeAnd = new ExpressionNode("NODE_OP", "AND");
			exprNodeAnd.setChildNodes(expressionNodes);
			query.setWhereClauseStructure(exprNodeAnd);
		}
		return query;
	}

	private String transformToEntityQuery(String jpaQueryStr) {
		// query at this point is : select <something> from <table> <alias> ... to be replaced by select <alias> from <table> <alias> ...
		// The following replacement works also in case query is containing joins to other entities, but MAIN entity must be the first one in the FROM clause!!!
		// TODO refactor this code to be more reliable
		String toReturn = jpaQueryStr.replaceAll("(?i)select (.*) from (\\w+) (\\w+)", "select $3 from $2 $3");
		return toReturn;
	}

	private Column getDependenceColumns(List columns, String depField) {
		Column toReturn = null;
		for (int i = 0; i < columns.size(); i++) {
			Column c = (Column) columns.get(i);
			if (c.getField().equalsIgnoreCase(depField)) {
				toReturn = c;
				break;
			}
		}
		return toReturn;
	}

	private void logQuery(String jpqlQuery) {
		UserProfile userProfile = UserProfileManager.getProfile();
		auditlogger.info("[" + userProfile.getUserId() + "]:: JPQL: " + jpqlQuery);
		logger.debug("[" + userProfile.getUserId() + "]:: JPQL: " + jpqlQuery);
	}

}
