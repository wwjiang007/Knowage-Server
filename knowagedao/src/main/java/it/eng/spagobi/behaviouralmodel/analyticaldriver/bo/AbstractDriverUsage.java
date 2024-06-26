package it.eng.spagobi.behaviouralmodel.analyticaldriver.bo;

import java.util.Iterator;
import java.util.List;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

import org.hibernate.validator.constraints.NotEmpty;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import it.eng.spagobi.services.validation.AlphanumericNoSpaces;
import it.eng.spagobi.services.validation.ExtendedAlphanumeric;

public class AbstractDriverUsage {

	private Integer id;
	/* PAR_ID NUMBER N Parameter identifier */
	@NotNull
	private Integer parID = null;

	private Parameter parameter = null;

	/*
	 * LABEL VARCHAR2(36) Y Parameter label in BIObj use (short textual identifier)
	 */
	@NotEmpty
	@ExtendedAlphanumeric
	@Size(max = 40)
	private String label = null;

	/* COL_SPAN Span column parameter. */
	private Integer colSpan = null;

	/* thick_perc column parameter. */
	private Integer thickPerc = null;

	/*
	 * PROG NUMBER N Ordinal number for sorting
	 */
	private Integer prog = null;

	/*
	 * PRIORITY NUMBER N Ordinal number for sorting BIObjectParameters relative to one BIObject
	 */
	private Integer priority = null;

	/* PARURL_NM VARCHAR2(18) Y Parameter name in HTTP request. */
	@NotEmpty
	@AlphanumericNoSpaces
	@Size(max = 20)
	private String parameterUrlName = null;

	/* VALUES LIST OF THE PARAMETER (STRINGS) */
	private List parameterValues = null;

	private List parameterValuesDescription = null;

	/* transient flag. set to true for parameters buil on the fly */
	private boolean transientParmeters = false;

	// default value is false; when the parameter values are set and they are correct, this field must be set to true
	private boolean hasValidValues = false;

	// if isIterative is true, it means that the execution must be executed for each value of the parameter,
	// example: if the parameter values are "a" and "b" and isIterative = true, the document should be executed 2 times: the first time with "a"
	// and second time with "b"; if isIterative = false, document should be executed only with time with "a" and "b" at the same time.
	// It is used by the scheduler.
	private boolean isIterative = false;

	private ParameterValuesRetriever parameterValuesRetriever = null;

	/* REQ_FL NUMBER Y Parameter required flag. */
	private Integer required = null;

	/* MOD_FL NUMBER Y Parameter modifiable flag. */
	private Integer modifiable = null;

	/* VIEW_FL NUMBER Y Paramenter visibility flag. */
	@JsonDeserialize(using = BooleanJsonDeserializer.class)
	@JsonSerialize(using = BooleanJsonSerializer.class)
	private Integer visible = null;

	/* MULT_FL NUMBER Y Multivalue parameter. */
	private Integer multivalue = null;

	public Integer getModifiable() {
		return modifiable;
	}

	/**
	 * Sets the modifiable.
	 *
	 * @param modifiable The modifiable to set.
	 */
	public void setModifiable(Integer modifiable) {
		this.modifiable = modifiable;
	}

	/**
	 * Gets the multivalue attribute that is equal to 0 if the parameter is not multivalue, 1 otherwise .
	 *
	 * @return Returns the multivalue.
	 */
	@JsonIgnore
	public Integer getMultivalue() {
		return multivalue;
	}

	@JsonProperty(value = "multivalue")
	public boolean isMultivalue() {
		if (multivalue == null)
			return false;
		return multivalue.intValue() > 0;
	}

	/**
	 * Sets the multivalue.
	 *
	 * @param multivalue The multivalue to set.
	 */
	@JsonIgnore
	public void setMultivalue(Integer multivalue) {
		this.multivalue = multivalue;
	}

	public void setMultivalue(boolean multivalue) {
		if (multivalue)
			this.multivalue = 1;
		else
			this.multivalue = 0;
	}

	/**
	 * Gets the parameter url name.
	 *
	 * @return Returns the parameterUrlName.
	 */

	@JsonIgnore
	public Integer getRequired() {
		return required;
	}

	@JsonProperty(value = "required")
	public boolean isRequired() {
		if (required == null)
			return false;
		return required.intValue() > 0;
	}

	/**
	 * Sets the required.
	 *
	 * @param required The required to set.
	 */
	@JsonIgnore
	public void setRequired(Integer required) {
		this.required = required;
	}

	public void setRequired(boolean required) {
		if (required)
			this.required = 1;
		else
			this.required = 0;
	}

	/**
	 * Gets the visible.
	 *
	 * @return Returns the visible.
	 */
	public Integer getVisible() {
		return visible;
	}

	/**
	 * Sets the visible.
	 *
	 * @param visible The visible to set.
	 */
	public void setVisible(Integer visible) {
		this.visible = visible;
	}

	/**
	 * Gets the label.
	 *
	 * @return Returns the label.
	 */
	public String getLabel() {
		return label;
	}

	/**
	 * Sets the label.
	 *
	 * @param label The label to set.
	 */
	public void setLabel(String label) {
		this.label = label;
	}

	/**
	 * Gets the modifiable.
	 *
	 * @return Returns the modifiable.
	 */

	/**
	 * Gets the parameter url name.
	 *
	 * @return Returns the parameterUrlName.
	 */
	public String getParameterUrlName() {
		return parameterUrlName;
	}

	/**
	 * Sets the parameter url name.
	 *
	 * @param parameterUrlName The parameterUrlName to set.
	 */
	public void setParameterUrlName(String parameterUrlName) {
		this.parameterUrlName = parameterUrlName;
	}

	/**
	 * Gets the parameter values.
	 *
	 * @return Returns the parameterValues.
	 */
	public List getParameterValues() {
		return parameterValues;
	}

	/**
	 * Gets the parameter values as a unique String (values are separated by ";"). If the parameter has no values set, null is returned.
	 *
	 * @return Returns the parameter values as a unique String (values are separated by ";").
	 */
	@JsonIgnore
	public String getParameterValuesAsString() {
		if (parameterValues == null || parameterValues.isEmpty()) {
			return null;
		}
		StringBuilder buffer = new StringBuilder();
		Iterator it = parameterValues.iterator();
		while (it.hasNext()) {
			String aValue = (String) it.next();
			buffer.append(aValue);
			if (it.hasNext()) {
				buffer.append(";");
			}
		}
		return buffer.toString();
	}

	/**
	 * Sets the parameter values.
	 *
	 * @param parameterValues The parameterValues to set.
	 */
	public void setParameterValues(List parameterValues) {
		this.parameterValues = parameterValues;
	}

	/**
	 * Gets the par id.
	 *
	 * @return Returns the parID.
	 */
	public Integer getParID() {
		return parID;
	}

	/**
	 * Sets the par id.
	 *
	 * @param parID The parID to set.
	 */
	public void setParID(Integer parID) {
		this.parID = parID;
	}

	/**
	 * Gets the prog.
	 *
	 * @return Returns the prog.
	 */
	public Integer getProg() {
		return prog;
	}

	/**
	 * Sets the prog.
	 *
	 * @param prog The prog to set.
	 */
	public void setProg(Integer prog) {
		this.prog = prog;
	}

	/**
	 * Gets the required.
	 *
	 * @return Returns the required.
	 */

	/**
	 * Gets the parameter.
	 *
	 * @return the Parameter object
	 */
	public Parameter getParameter() {
		return parameter;
	}

	/**
	 * Sets the parameter.
	 *
	 * @param parameter The Parameter to set
	 */
	public void setParameter(Parameter parameter) {
		this.parameter = parameter;
	}

	/**
	 * Gets the priority.
	 *
	 * @return Returns the priority
	 */
	public Integer getPriority() {
		return priority;
	}

	/**
	 * Sets the priority.
	 *
	 * @param priority The priority to set
	 */
	public void setPriority(Integer priority) {
		this.priority = priority;
	}

	/**
	 * Checks if is transient parmeters.
	 *
	 * @return true, if is transient parmeters
	 */
	public boolean isTransientParmeters() {
		return transientParmeters;
	}

	/**
	 * Sets the transient parmeters.
	 *
	 * @param transientParmeters the new transient parmeters
	 */
	public void setTransientParmeters(boolean transientParmeters) {
		this.transientParmeters = transientParmeters;
	}

	/**
	 * Checks for valid values.
	 *
	 * @return true, if successful
	 */
	public boolean hasValidValues() {
		return hasValidValues;
	}

	/**
	 * Sets the checks for valid values.
	 *
	 * @param hasValidValues the new checks for valid values
	 */
	public void setHasValidValues(boolean hasValidValues) {
		this.hasValidValues = hasValidValues;
	}

	/**
	 * Gets the parameter values description.
	 *
	 * @return the parameter values description
	 */
	public List getParameterValuesDescription() {
		return parameterValuesDescription;
	}

	/**
	 * Sets the parameter values description.
	 *
	 * @param parameterValuesDescription the new parameter values description
	 */
	public void setParameterValuesDescription(List parameterValuesDescription) {
		this.parameterValuesDescription = parameterValuesDescription;
	}

	public boolean isIterative() {
		return isIterative;
	}

	public void setIterative(boolean isIterative) {
		this.isIterative = isIterative;
	}

	public ParameterValuesRetriever getParameterValuesRetriever() {
		return parameterValuesRetriever;
	}

	public void setParameterValuesRetriever(ParameterValuesRetriever parameterValuesRetriever) {
		this.parameterValuesRetriever = parameterValuesRetriever;
	}

	public Integer getColSpan() {
		return colSpan;
	}

	public void setColSpan(Integer colSpan) {
		this.colSpan = colSpan;
	}

	public Integer getThickPerc() {
		return thickPerc;
	}

	public void setThickPerc(Integer thickPerc) {
		this.thickPerc = thickPerc;
	}

	public Integer getId() {
		return id;
	}

	public void setId(Integer id) {
		this.id = id;
	}

	public boolean isHasValidValues() {
		return hasValidValues;
	}

}
