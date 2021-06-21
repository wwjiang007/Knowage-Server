/*
 * Knowage, Open Source Business Intelligence suite
 * Copyright (C) 2021 Engineering Ingegneria Informatica S.p.A.

 * Knowage is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * Knowage is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package it.eng.knowage.knowageapi.dao;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

import java.sql.SQLException;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.persistence.EntityManager;
import javax.persistence.EntityTransaction;
import javax.sql.rowset.serial.SerialException;

import org.apache.commons.lang3.RandomStringUtils;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import it.eng.knowage.knowageapi.dao.dto.SbiCatalogFunction;
import it.eng.knowage.knowageapi.dao.dto.SbiFunctionInputColumn;
import it.eng.knowage.knowageapi.dao.dto.SbiFunctionInputVariable;
import it.eng.knowage.knowageapi.dao.dto.SbiFunctionOutputColumn;
import it.eng.knowage.knowageapi.dao.dto.SbiObjFunction;

/**
 * @author Marco Libanori
 */
@SpringBootTest
@ActiveProfiles("test")
class SbiCatalogFunctionDaoTest {

	@Autowired
	private SbiCatalogFunctionDao dao;

	@Autowired
	@Qualifier("knowage-functioncatalog")
	private EntityManager em;

	@Test
	void getAll() {
		List<SbiCatalogFunction> all = dao.findAll();

		System.out.println(all);

		assertNotEquals(0, all.size());
	}

	@Test
	void getNothing() {
		List<SbiCatalogFunction> all = dao.findAll("nothing");

		assertEquals(0, all.size());
	}

	@Test
	void create() throws SerialException, SQLException {

		String label = RandomStringUtils.randomAlphanumeric(12);

		SbiCatalogFunction n = new SbiCatalogFunction();

		Set<SbiFunctionInputColumn> inputColumns = new HashSet<>();
		Set<SbiFunctionInputVariable> inputVariables = new HashSet<>();
		Set<SbiObjFunction> objFunctions = new HashSet<>();
		Set<SbiFunctionOutputColumn> outputColumns = new HashSet<>();

		SbiFunctionInputColumn inCol = new SbiFunctionInputColumn();
		inCol.setColType("type");
		inCol.getId().setColName("name");
		inCol.setFunction(n);

		inputColumns.add(inCol);

		SbiFunctionOutputColumn outCol = new SbiFunctionOutputColumn();
		outCol.setColFieldType("type");
		outCol.setColType("type");
		outCol.setFunction(n);
		outCol.getId().setColName("name");

		outputColumns.add(outCol);

		SbiFunctionInputVariable inVar = new SbiFunctionInputVariable();
		inVar.setFunction(n);
		inVar.getId().setVarName("name");
		inVar.setVarType("type");
		inVar.setVarValue("value");

		inputVariables.add(inVar);

		n.setBenchmarks("benchmark");
		n.setDescription("description");
		n.setFamily("family");
		n.setInputColumns(inputColumns);
		n.setInputVariables(inputVariables);
		n.setKeywords("keyword");
		n.setLabel(label);
		n.setLanguage("language");
		n.setName("name");
//		n.setObjFunctions(objFunctions);
		n.setOfflineScriptTrain("offlineScriptTrain");
		n.setOfflineScriptUse("offlineScriptUse");
		n.setOnlineScript("onlineScript");
		n.setOutputColumns(outputColumns);
		n.setOwner("biadmin");
		n.setType("type");

		EntityTransaction transaction = em.getTransaction();
		transaction.begin();

		n = dao.create(n);

		transaction.commit();



		transaction = em.getTransaction();
		transaction.begin();

		dao.delete(n.getFunctionId());

		transaction.commit();
	}

}
