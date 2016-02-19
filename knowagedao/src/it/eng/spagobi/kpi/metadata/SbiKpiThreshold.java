package it.eng.spagobi.kpi.metadata;

// Generated 19-feb-2016 16.57.14 by Hibernate Tools 3.6.0

import it.eng.spagobi.commons.metadata.SbiDomains;
import it.eng.spagobi.commons.metadata.SbiHibernateModel;

import java.util.HashSet;
import java.util.Set;

/**
 * SbiKpiThreshold generated by hbm2java
 */
public class SbiKpiThreshold extends SbiHibernateModel implements java.io.Serializable {

	private Integer id;
	private String name;
	private String description;
	private SbiDomains type;
	private Set<SbiKpiThreshold> sbiKpiThresholdValues = new HashSet(0);

	public SbiKpiThreshold() {
	}

	public Integer getId() {
		return this.id;
	}

	public void setId(Integer id) {
		this.id = id;
	}

	public String getName() {
		return this.name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getDescription() {
		return this.description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public SbiDomains getType() {
		return this.type;
	}

	public void setType(SbiDomains type) {
		this.type = type;
	}

	public Set getSbiKpiThresholdValues() {
		return this.sbiKpiThresholdValues;
	}

	public void setSbiKpiThresholdValues(Set sbiKpiThresholdValues) {
		this.sbiKpiThresholdValues = sbiKpiThresholdValues;
	}

}
