package it.eng.knowage.engine.cockpit.api.export.excel.crosstab;

import java.awt.Color;

/* SpagoBI, the Open Source Business Intelligence suite

 * Copyright (C) 2012 Engineering Ingegneria Informatica S.p.A. - SpagoBI Competency Center
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0, without the "Incompatible With Secondary Licenses" notice.
 * If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;

import org.apache.log4j.Logger;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.CreationHelper;
import org.apache.poi.ss.usermodel.DataFormat;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.json.JSONException;
import org.json.JSONObject;

import com.jamonapi.Monitor;
import com.jamonapi.MonitorFactory;

import it.eng.knowage.engine.cockpit.api.crosstable.CrossTab;
import it.eng.knowage.engine.cockpit.api.crosstable.CrossTab.CellType;
import it.eng.knowage.engine.cockpit.api.crosstable.CrossTab.MeasureInfo;
import it.eng.knowage.engine.cockpit.api.crosstable.MeasureFormatter;
import it.eng.knowage.engine.cockpit.api.crosstable.MeasureScaleFactorOption;
import it.eng.knowage.engine.cockpit.api.crosstable.Node;
import it.eng.knowage.engine.cockpit.api.export.excel.Threshold;
import it.eng.qbe.serializer.SerializationException;
import it.eng.spagobi.utilities.messages.EngineMessageBundle;

/**
 * Exports the crosstab data (formatted as a JSON object in input) into a XLS file. The JSON object should have this structure (a node is {node_key:"Text",
 * node_childs:[...]}): columns: {...} contains tree node structure of the columns' headers rows: {...} contains tree node structure of the rows' headers data:
 * [[...], [...], ...] 2-dimensional matrix containing crosstab data
 *
 * @author Alberto Ghedin (alberto.ghedin@eng.it), Davide Zerbetto (davide.zerbetto@eng.it)
 */
public class CrosstabXLSExporter {

	/** Logger component. */
	public static transient Logger logger = Logger.getLogger(CrosstabXLSExporter.class);

	/** Configuration properties */
	public static final String PROPERTY_HEADER_FONT_SIZE = "HEADER_FONT_SIZE";
	public static final String PROPERTY_HEADER_COLOR = "HEADER_COLOR";
	public static final String PROPERTY_HEADER_BACKGROUND_COLOR = "HEADER_BACKGROUND_COLOR";
	public static final String PROPERTY_HEADER_BORDER_COLOR = "HEADER_BORDER_COLOR";
	public static final String PROPERTY_CELL_FONT_SIZE = "CELL_FONT_SIZE";
	public static final String PROPERTY_CELL_COLOR = "CELL_COLOR";
	public static final String PROPERTY_CELL_BACKGROUND_COLOR = "CELL_BACKGROUND_COLOR";
	public static final String PROPERTY_CELL_BORDER_COLOR = "CELL_BORDER_COLOR";
	public static final String PROPERTY_DIMENSION_NAME_COLOR = "DIMENSION_NAME_COLOR";
	public static final String PROPERTY_DIMENSION_NAME_BACKGROUND_COLOR = "HEADER_DIMENSION_NAME_BACKGROUND_COLOR";
	public static final String PROPERTY_FONT_NAME = "FONT_NAME";

	public static final String PROPERTY_CALCULATED_FIELD_DECIMALS = "CALCULATED_FIELD_DECIMALS";

	public static final short DEFAULT_HEADER_FONT_SIZE = 8;
	public static final String DEFAULT_HEADER_COLOR = "BLACK";
	public static final String DEFAULT_HEADER_BACKGROUND_COLOR = "GREY_25_PERCENT";
	public static final String DEFAULT_HEADER_BORDER_COLOR = "WHITE";
	public static final short DEFAULT_CELL_FONT_SIZE = 8;
	public static final String DEFAULT_CELL_COLOR = "BLACK";
	public static final String DEFAULT_CELL_BACKGROUND_COLOR = "WHITE";
	public static final String DEFAULT_CELL_BORDER_COLOR = "BLACK";
	public static final String DEFAULT_DIMENSION_NAME_COLOR = "BLACK";
	public static final String DEFAULT_DIMENSION_NAME_BACKGROUND_COLOR = "LIGHT_BLUE";
	public static final String DEFAULT_FONT_NAME = "Verdana";
	public static final int DEFAULT_CALCULATED_FIELD_DECIMALS = 2;

	private Properties properties;
	private Map<String, List<Threshold>> thresholdColorsMap;
	private JSONObject variables = new JSONObject();

	public CrosstabXLSExporter(Properties properties, JSONObject variables) {
		super();
		if (properties == null) {
			this.properties = new Properties();
		} else {
			this.properties = properties;
		}
		this.variables = variables;
	}

	public CrosstabXLSExporter(Properties properties, JSONObject variables, Map<String, List<Threshold>> thresholdColorsMap) {
		super();
		if (properties == null) {
			this.properties = new Properties();
		} else {
			this.properties = properties;
		}
		if (thresholdColorsMap == null) {
			this.thresholdColorsMap = new HashMap<String, List<Threshold>>();
		} else {
			this.thresholdColorsMap = thresholdColorsMap;
		}
		this.variables = variables;
	}

	public void setProperty(String propertyName, Object propertyValue) {
		this.properties.put(propertyName, propertyValue);
	}

	public Object getProperty(String propertyName) {
		return this.properties.get(propertyName);
	}

	public int fillExcelSheetWithData(Sheet sheet, CrossTab cs, CreationHelper createHelper, int startRow, Locale locale)
			throws SerializationException, JSONException {
		int columnsDepth = cs.getColumnsRoot().getSubTreeDepth();
		int rowsDepth = cs.getRowsRoot().getSubTreeDepth();

		// + 1 because there may be also the bottom row with the totals
		int totalRowsNumber = cs.getTotalNumberOfRows();

		for (int i = 0; i < totalRowsNumber; i++) {
			sheet.createRow(startRow + i);
		}

		CellStyle memberCellStyle = this.buildHeaderCellStyle(sheet);
		CellStyle dimensionCellStyle = this.buildDimensionCellStyle(sheet);

		// build headers for column first ...
		Monitor buildColumnsHeaderMonitor = MonitorFactory.start("CockpitEngine.CrossTabXLSExporter.buildColumnsHeaderMonitor");
		buildColumnsHeader(sheet, cs, cs.getColumnsRoot().getChildren(), startRow, rowsDepth - 1, createHelper, locale, memberCellStyle, dimensionCellStyle, 0);
		buildColumnsHeaderMonitor.stop();

		// ... then build headers for rows ....
		Monitor buildRowsHeaderMonitor = MonitorFactory.start("CockpitEngine.CrossTabXLSExporter.buildRowsHeaderMonitor");
		buildRowsHeaders(sheet, cs, cs.getRowsRoot().getChildren(), columnsDepth - 1 + startRow, 0, createHelper, locale, memberCellStyle);
		buildRowsHeaderMonitor.stop();

		// then put the matrix data
		Monitor buildDataMatrixMonitor = MonitorFactory.start("CockpitEngine.CrossTabXLSExporter.buildDataMatrixMonitor");
		buildDataMatrix(sheet, cs, columnsDepth + startRow - 1, rowsDepth - 1, createHelper);
		buildDataMatrixMonitor.stop();

		// finally add row titles
		Monitor buildRowHeaderTitleMonitor = MonitorFactory.start("CockpitEngine.CrossTabXLSExporter.buildRowHeaderTitleMonitor");
		buildRowHeaderTitle(sheet, cs, columnsDepth - 2, 0, startRow, createHelper, locale, dimensionCellStyle);
		buildRowHeaderTitleMonitor.stop();

		return startRow + totalRowsNumber;
	}

	/**
	 * Sheet initialization. We create as many rows as it is required to contain the crosstab.
	 *
	 * @param sheet The XLS sheet
	 * @param json  The crosstab data (it must have been enriched with the calculateDescendants method)
	 * @throws JSONException
	 */
	public int initSheet(Sheet sheet, CrossTab cs) throws JSONException {

		int columnsDepth = cs.getColumnsRoot().getSubTreeDepth();
		int rowsNumber = cs.getRowsRoot().getSubTreeDepth();
		// + 1 because there may be also the bottom row with the totals
		int totalRowsNumber = columnsDepth + rowsNumber + 1;
		for (int i = 0; i < totalRowsNumber + 4; i++) {
			sheet.createRow(i);
		}
		return totalRowsNumber + 4;
	}

	protected int buildDataMatrix(Sheet sheet, CrossTab cs, int rowOffset, int columnOffset, CreationHelper createHelper) throws JSONException {
		MeasureFormatter measureFormatter = new MeasureFormatter(cs);
		CellStyle cellStyleForNA = buildNACellStyle(sheet);
		String[][] dataMatrix = cs.getDataMatrix();
		int numOfMeasures = cs.getMeasures().size();

		Map<Integer, CellStyle> decimalFormats = new HashMap<Integer, CellStyle>();
		int rowNum = 0;
		logger.debug("Data matrix number of rows: " + dataMatrix.length);
		logger.debug("Data matrix number of columns: " + dataMatrix[0].length);

		for (int i = 0; i < dataMatrix.length; i++) {
			rowNum = rowOffset + i;
			Row row = sheet.getRow(rowNum);
			if (row == null) {
				row = sheet.createRow(rowNum);
			}
			for (int j = 0; j < dataMatrix[0].length; j++) {
				String text = dataMatrix[i][j];
				int columnNum = columnOffset + j;
				Cell cell = row.createCell(columnNum);
				try {
					Monitor valueFormattedMonitor = MonitorFactory.start("CockpitEngine.export.excel.CrossTabExporter.buildDataMatrix.valueFormattedMonitor");
					double value = Double.parseDouble(text);
					Double valueFormatted = measureFormatter.applyScaleFactor(value, i, j);
					valueFormattedMonitor.stop();
					Monitor cellStyleMonitor = MonitorFactory.start("CockpitEngine.export.excel.CrossTabExporter.buildDataMatrix.cellStyleMonitor");
					int measureIdx = j % numOfMeasures;
					String measureId = getMeasureId(cs, measureIdx);
					int decimals = measureFormatter.getFormatXLS(i, j);
					CellStyle style = getStyle(decimals, decimalFormats, sheet, createHelper, cs.getCellType(i, j), measureId, value);
					cellStyleMonitor.stop();
					Monitor buildCellMonitor = MonitorFactory.start("CockpitEngine.export.excel.CrossTabExporter.buildDataMatrix.buildCellMonitor");
					cell.setCellValue(valueFormatted);
					cell.setCellType(this.getCellTypeNumeric());
					cell.setCellStyle(style);
					buildCellMonitor.stop();
				} catch (NumberFormatException e) {
					logger.debug("Text " + text + " is not recognized as a number");
					cell.setCellValue(createHelper.createRichTextString(text));
					cell.setCellType(this.getCellTypeString());
					cell.setCellStyle(cellStyleForNA);
				}

			}
		}
		return rowNum;
	}

	private String getMeasureId(CrossTab cs, int index) {
		List<MeasureInfo> measures = cs.getMeasures();
		MeasureInfo measure = measures.get(index);
		String measureId = measure.getId();
		return measureId;
	}

	protected org.apache.poi.ss.usermodel.CellType getCellTypeNumeric() {
		return org.apache.poi.ss.usermodel.CellType.NUMERIC;
	}

	protected org.apache.poi.ss.usermodel.CellType getCellTypeString() {
		return org.apache.poi.ss.usermodel.CellType.STRING;
	}

	public CellStyle buildNACellStyle(Sheet sheet) {
		CellStyle cellStyleForNA = this.buildDataCellStyle(sheet);
		cellStyleForNA.setAlignment(HorizontalAlignment.CENTER);
		return cellStyleForNA;
	}

	/**
	 * Builds the rows' headers recursively with this order: |-----|-----|-----| | | | 3 | | | |-----| | | 2 | 4 | | | |-----| | 1 | | 5 | | |-----|-----| | | |
	 * 7 | | | 6 |-----| | | | 8 | |-----|-----|-----| | | | 11 | | 9 | 10 |-----| | | | 12 | |-----|-----|-----|
	 *
	 * @param sheet        The sheet of the XLS file
	 * @param siblings     The siblings nodes of the headers structure
	 * @param rowNum       The row number where the first sibling must be inserted
	 * @param columnNum    The column number where the siblings must be inserted
	 * @param createHelper The file creation helper
	 * @throws JSONException
	 */
	protected void buildRowsHeaders(Sheet sheet, CrossTab cs, List<Node> siblings, int rowNum, int columnNum, CreationHelper createHelper, Locale locale,
			CellStyle cellStyle) throws JSONException {
		int rowsCounter = rowNum;

		for (int i = 0; i < siblings.size(); i++) {
			Node aNode = siblings.get(i);
			List<Node> childs = aNode.getChildren();
			Row row = sheet.getRow(rowsCounter);
			Cell cell = row.createCell(columnNum);
			String text = aNode.getDescription();

			if (cs.isMeasureOnRow() && (childs == null || childs.size() <= 0)) {
				// apply the measure scale factor
				text = MeasureScaleFactorOption.getScaledName(text, cs.getMeasureScaleFactor(text), locale);
			}
			cell.setCellValue(createHelper.createRichTextString(text));
			cell.setCellType(this.getCellTypeString());

			cell.setCellStyle(cellStyle);

			int descendants = aNode.getLeafsNumber();
			if (descendants > 1) {
				sheet.addMergedRegion(new CellRangeAddress(rowsCounter, // first row (0-based)
						rowsCounter + descendants - 1, // last row (0-based)
						columnNum, // first column (0-based)
						columnNum // last column (0-based)
				));
			}

			if (childs != null && childs.size() > 0) {
				buildRowsHeaders(sheet, cs, childs, rowsCounter, columnNum + 1, createHelper, locale, cellStyle);
			}
			int increment = descendants > 1 ? descendants : 1;
			rowsCounter = rowsCounter + increment;
		}
	}

	/**
	 * Add the title of the columns in the row headers
	 *
	 * @param sheet
	 * @param titles              list of titles
	 * @param columnHeadersNumber number of column headers
	 * @param startColumn         first column of the crosstab in the xls
	 * @param startRow            first row of the crosstab in the xls
	 * @param createHelper
	 * @throws JSONException
	 */
	protected void buildRowHeaderTitle(Sheet sheet, CrossTab cs, int columnHeadersNumber, int startColumn, int startRow, CreationHelper createHelper,
			Locale locale, CellStyle cellStyle) throws JSONException {
		List<String> titles = cs.getRowHeadersTitles();

		if (titles != null) {

			Row row = sheet.getRow(startRow + columnHeadersNumber);
			for (int i = 0; i < titles.size(); i++) {

				Cell cell = row.createCell(startColumn + i);
				it.eng.knowage.engine.cockpit.api.crosstable.CrosstabDefinition.Row aRowDef = cs.getCrosstabDefinition().getRows().get(i);

				String text = titles.get(i);
				String variable = aRowDef.getVariable();
				if (variables.has(variable)) {
					text = variables.getString(variable);
				}

				cell.setCellValue(createHelper.createRichTextString(text));
				cell.setCellType(this.getCellTypeString());
				cell.setCellStyle(cellStyle);
			}
			if (cs.isMeasureOnRow()) {
				Cell cell = row.createCell(startColumn + titles.size());
				String text = "Measures";
				if (locale != null) {
					text = EngineMessageBundle.getMessage("worksheet.export.crosstab.header.measures", locale);
				}
				cell.setCellValue(createHelper.createRichTextString(text));
				cell.setCellType(this.getCellTypeString());
				cell.setCellStyle(cellStyle);
			}
		}
	}

	public CellStyle buildDimensionCellStyle(Sheet sheet) {
		CellStyle cellStyle = sheet.getWorkbook().createCellStyle();
		cellStyle.setAlignment(HorizontalAlignment.CENTER);
		cellStyle.setVerticalAlignment(VerticalAlignment.CENTER);

		String headerBGColor = (String) this.getProperty(PROPERTY_DIMENSION_NAME_BACKGROUND_COLOR);
		logger.debug("Header background color : " + headerBGColor);
		short backgroundColorIndex = headerBGColor != null ? IndexedColors.valueOf(headerBGColor).getIndex()
				: IndexedColors.valueOf(DEFAULT_DIMENSION_NAME_BACKGROUND_COLOR).getIndex();
		cellStyle.setFillForegroundColor(backgroundColorIndex);

		cellStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

		cellStyle.setBorderBottom(BorderStyle.THIN);
		cellStyle.setBorderLeft(BorderStyle.THIN);
		cellStyle.setBorderRight(BorderStyle.THIN);
		cellStyle.setBorderTop(BorderStyle.THIN);

		String bordeBorderColor = (String) this.getProperty(PROPERTY_HEADER_BORDER_COLOR);
		logger.debug("Header border color : " + bordeBorderColor);
		short borderColorIndex = bordeBorderColor != null ? IndexedColors.valueOf(bordeBorderColor).getIndex()
				: IndexedColors.valueOf(DEFAULT_HEADER_BORDER_COLOR).getIndex();

		cellStyle.setLeftBorderColor(borderColorIndex);
		cellStyle.setRightBorderColor(borderColorIndex);
		cellStyle.setBottomBorderColor(borderColorIndex);
		cellStyle.setTopBorderColor(borderColorIndex);

		Font font = sheet.getWorkbook().createFont();

		Short headerFontSize = (Short) this.getProperty(PROPERTY_HEADER_FONT_SIZE);
		logger.debug("Header font size : " + headerFontSize);
		short headerFontSizeShort = headerFontSize != null ? headerFontSize.shortValue() : DEFAULT_HEADER_FONT_SIZE;
		font.setFontHeightInPoints(headerFontSizeShort);

		String fontName = (String) this.getProperty(PROPERTY_FONT_NAME);
		logger.debug("Font name : " + fontName);
		fontName = fontName != null ? fontName : DEFAULT_FONT_NAME;
		font.setFontName(fontName);

		String color = (String) this.getProperty(PROPERTY_DIMENSION_NAME_COLOR);
		logger.debug("Dimension color : " + color);
		short colorIndex = bordeBorderColor != null ? IndexedColors.valueOf(color).getIndex() : IndexedColors.valueOf(DEFAULT_DIMENSION_NAME_COLOR).getIndex();
		font.setColor(colorIndex);

		font.setBold(true);
		font.setItalic(true);
		cellStyle.setFont(font);
		return cellStyle;
	}

	public CellStyle buildHeaderCellStyle(Sheet sheet) {
		CellStyle cellStyle = sheet.getWorkbook().createCellStyle();
		cellStyle.setAlignment(HorizontalAlignment.LEFT);
		cellStyle.setVerticalAlignment(VerticalAlignment.CENTER);

		String headerBGColor = (String) this.getProperty(PROPERTY_HEADER_BACKGROUND_COLOR);
		logger.debug("Header background color : " + headerBGColor);
		short backgroundColorIndex = headerBGColor != null ? IndexedColors.valueOf(headerBGColor).getIndex()
				: IndexedColors.valueOf(DEFAULT_HEADER_BACKGROUND_COLOR).getIndex();
		cellStyle.setFillForegroundColor(backgroundColorIndex);

		cellStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

		cellStyle.setBorderBottom(BorderStyle.THIN);
		cellStyle.setBorderLeft(BorderStyle.THIN);
		cellStyle.setBorderRight(BorderStyle.THIN);
		cellStyle.setBorderTop(BorderStyle.THIN);

		String bordeBorderColor = (String) this.getProperty(PROPERTY_HEADER_BORDER_COLOR);
		logger.debug("Header border color : " + bordeBorderColor);
		short borderColorIndex = bordeBorderColor != null ? IndexedColors.valueOf(bordeBorderColor).getIndex()
				: IndexedColors.valueOf(DEFAULT_HEADER_BORDER_COLOR).getIndex();

		cellStyle.setLeftBorderColor(borderColorIndex);
		cellStyle.setRightBorderColor(borderColorIndex);
		cellStyle.setBottomBorderColor(borderColorIndex);
		cellStyle.setTopBorderColor(borderColorIndex);

		Font font = sheet.getWorkbook().createFont();

		Short headerFontSize = (Short) this.getProperty(PROPERTY_HEADER_FONT_SIZE);
		logger.debug("Header font size : " + headerFontSize);
		short headerFontSizeShort = headerFontSize != null ? headerFontSize.shortValue() : DEFAULT_HEADER_FONT_SIZE;
		font.setFontHeightInPoints(headerFontSizeShort);

		String fontName = (String) this.getProperty(PROPERTY_FONT_NAME);
		logger.debug("Font name : " + fontName);
		fontName = fontName != null ? fontName : DEFAULT_FONT_NAME;
		font.setFontName(fontName);

		String headerColor = (String) this.getProperty(PROPERTY_HEADER_COLOR);
		logger.debug("Header color : " + headerColor);
		short headerColorIndex = bordeBorderColor != null ? IndexedColors.valueOf(headerColor).getIndex()
				: IndexedColors.valueOf(DEFAULT_HEADER_COLOR).getIndex();
		font.setColor(headerColorIndex);

		font.setBold(true);
		cellStyle.setFont(font);
		return cellStyle;
	}

	public CellStyle buildDataCellStyle(Sheet sheet) {
		CellStyle cellStyle = sheet.getWorkbook().createCellStyle();
		cellStyle.setAlignment(HorizontalAlignment.RIGHT);
		cellStyle.setVerticalAlignment(VerticalAlignment.CENTER);

		String cellBGColor = (String) this.getProperty(PROPERTY_CELL_BACKGROUND_COLOR);
		logger.debug("Cell background color : " + cellBGColor);
		short backgroundColorIndex = cellBGColor != null ? IndexedColors.valueOf(cellBGColor).getIndex()
				: IndexedColors.valueOf(DEFAULT_CELL_BACKGROUND_COLOR).getIndex();
		cellStyle.setFillForegroundColor(backgroundColorIndex);

		cellStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

		cellStyle.setBorderBottom(BorderStyle.THIN);
		cellStyle.setBorderLeft(BorderStyle.THIN);
		cellStyle.setBorderRight(BorderStyle.THIN);
		cellStyle.setBorderTop(BorderStyle.THIN);

		String bordeBorderColor = (String) this.getProperty(PROPERTY_CELL_BORDER_COLOR);
		logger.debug("Cell border color : " + bordeBorderColor);
		short borderColorIndex = bordeBorderColor != null ? IndexedColors.valueOf(bordeBorderColor).getIndex()
				: IndexedColors.valueOf(DEFAULT_CELL_BORDER_COLOR).getIndex();

		cellStyle.setLeftBorderColor(borderColorIndex);
		cellStyle.setRightBorderColor(borderColorIndex);
		cellStyle.setBottomBorderColor(borderColorIndex);
		cellStyle.setTopBorderColor(borderColorIndex);

		Font font = sheet.getWorkbook().createFont();

		Short cellFontSize = (Short) this.getProperty(PROPERTY_CELL_FONT_SIZE);
		logger.debug("Cell font size : " + cellFontSize);
		short cellFontSizeShort = cellFontSize != null ? cellFontSize.shortValue() : DEFAULT_CELL_FONT_SIZE;
		font.setFontHeightInPoints(cellFontSizeShort);

		String fontName = (String) this.getProperty(PROPERTY_FONT_NAME);
		logger.debug("Font name : " + fontName);
		fontName = fontName != null ? fontName : DEFAULT_FONT_NAME;
		font.setFontName(fontName);

		String cellColor = (String) this.getProperty(PROPERTY_CELL_COLOR);
		logger.debug("Cell color : " + cellColor);
		short cellColorIndex = cellColor != null ? IndexedColors.valueOf(cellColor).getIndex() : IndexedColors.valueOf(DEFAULT_CELL_COLOR).getIndex();
		font.setColor(cellColorIndex);

		cellStyle.setFont(font);
		return cellStyle;
	}

	/**
	 * Builds the columns' headers recursively with this order: |------------------------------------------| | 1 | 9 |
	 * |------------------------------------------| | 2 | 5 | 10 | |-----------|-----------------|------------| | 3 | 4 | 6 | 7 | 8 | 11 | 12 |
	 * |------------------------------------------|
	 *
	 * @param sheet              The sheet of the XLS file
	 * @param siblings           The siblings nodes of the headers structure
	 * @param rowNum             The row number where the siblings must be inserted
	 * @param columnNum          The column number where the first sibling must be inserted
	 * @param createHelper       The file creation helper
	 * @param dimensionCellStyle The cell style for cells containing dimensions (i.e. attributes' names)
	 * @param memberCellStyle    The cell style for cells containing members (i.e. attributes' values)
	 * @throws JSONException
	 */
	protected void buildColumnsHeader(Sheet sheet, CrossTab cs, List<Node> siblings, int rowNum, int columnNum, CreationHelper createHelper, Locale locale,
			CellStyle memberCellStyle, CellStyle dimensionCellStyle, int recursionLevel) throws JSONException {
		int columnCounter = columnNum;

		for (int i = 0; i < siblings.size(); i++) {
			Node aNode = siblings.get(i);
			List<Node> childs = aNode.getChildren();
			Row row = sheet.getRow(rowNum);
			Cell cell = row.createCell(columnCounter);

			String text = aNode.getDescription();
			// only odd levels are levels (except the last one, since it contains measures' names)
			boolean isLevel = isLevel(recursionLevel, aNode);
			if (isLevel) {
				it.eng.knowage.engine.cockpit.api.crosstable.CrosstabDefinition.Column aColDef = cs.getCrosstabDefinition().getColumns()
						.get(recursionLevel / 2);
				String variable = aColDef.getVariable();
				if (variables.has(variable)) {
					text = variables.getString(variable);
				}
			}
			if (!cs.isMeasureOnRow() && (childs == null || childs.size() <= 0)) {
				// apply the measure scale factor
				text = MeasureScaleFactorOption.getScaledName(text, cs.getMeasureScaleFactor(text), locale);
			}

			cell.setCellValue(createHelper.createRichTextString(text));
			cell.setCellType(this.getCellTypeString());
			int descendants = aNode.getLeafsNumber();
			if (descendants > 1) {
				sheet.addMergedRegion(new CellRangeAddress(rowNum, // first row (0-based)
						rowNum, // last row (0-based)
						columnCounter, // first column (0-based)
						columnCounter + descendants - 1 // last column (0-based)
				));
			}

			/*
			 * Now we have to set the style properly according to the nature of the node: if it contains the name of a dimension or a member. Since the
			 * structure foresees that a list of members follows a dimension, we calculate the position of the node with respect to the leaves; in case it is
			 * odd, the cell contains a dimension; in case it is even, the cell contains a dimension.
			 */
			int distanceToLeaves = aNode.getDistanceFromLeaves();
			if (!cs.isMeasureOnRow()) {
				distanceToLeaves--;
			}
			boolean isDimensionNameCell = distanceToLeaves > 0 && (distanceToLeaves % 2) == 1;
			if (isDimensionNameCell) {
				cell.setCellStyle(dimensionCellStyle);
			} else {
				cell.setCellStyle(memberCellStyle);
			}

			if (childs != null && childs.size() > 0) {
				buildColumnsHeader(sheet, cs, childs, rowNum + 1, columnCounter, createHelper, locale, memberCellStyle, dimensionCellStyle, recursionLevel + 1);
			}
			int increment = descendants > 1 ? descendants : 1;
			columnCounter = columnCounter + increment;
		}
	}

	private boolean isLevel(int level, Node node) {
		if (level % 2 == 0) // only odd levels
			if (node.getDistanceFromLeaves() == 0) // discard measures
				return false;
			else
				return true;
		return false;
	}

	public CellStyle getStyle(int j, Map<Integer, CellStyle> decimalFormats, Sheet sheet, CreationHelper createHelper, CellType celltype, String measureId,
			Double value) {
		// XLSX manages thresholds background colours, XLS does not
		if (this instanceof CrosstabXLSXExporter)
			return getStyleForXLSX(j, sheet, createHelper, celltype, measureId, value);
		else
			return getStyleForXLS(j, decimalFormats, sheet, createHelper, celltype);
	}

	public CellStyle getStyleForXLSX(int j, Sheet sheet, CreationHelper createHelper, CellType celltype, String measureId, Double value) {

		if (celltype.equals(CellType.CF)) {
			j = this.getCalculatedFieldDecimals();
		}

		String decimals = "";

		for (int i = 0; i < j; i++) {
			decimals += "0";
		}

		XSSFCellStyle cellStyle = (XSSFCellStyle) this.buildDataCellStyle(sheet);
		DataFormat df = createHelper.createDataFormat();
		String format = "#,##0";
		if (decimals.length() > 0) {
			format += "." + decimals;
		}
		cellStyle.setDataFormat(df.getFormat(format));

		if (celltype.equals(CellType.TOTAL)) {
			cellStyle.setFillForegroundColor(IndexedColors.GREY_40_PERCENT.getIndex());
		}
		if (celltype.equals(CellType.CF)) {
			cellStyle.setFillForegroundColor(IndexedColors.DARK_YELLOW.getIndex());
		}
		if (celltype.equals(CellType.SUBTOTAL)) {
			cellStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
		}
		if (celltype.equals(CellType.DATA)) {
			cellStyle.setFillForegroundColor(getThresholdColor(measureId, value));
		}

		return cellStyle;
	}

	public CellStyle getStyleForXLS(int j, Map<Integer, CellStyle> decimalFormats, Sheet sheet, CreationHelper createHelper, CellType celltype) {

		int mapPosition = j;

		if (celltype.equals(CellType.TOTAL)) {
			mapPosition = j + 90000;
		} else if (celltype.equals(CellType.SUBTOTAL)) {
			mapPosition = j + 80000;
		} else if (celltype.equals(CellType.CF)) {
			mapPosition = j + 60000;
		}

		if (decimalFormats.get(mapPosition) != null)
			return decimalFormats.get(mapPosition);

		if (celltype.equals(CellType.CF)) {
			j = this.getCalculatedFieldDecimals();
		}

		String decimals = "";

		for (int i = 0; i < j; i++) {
			decimals += "0";
		}

		CellStyle cellStyle = this.buildDataCellStyle(sheet);
		DataFormat df = createHelper.createDataFormat();
		String format = "#,##0";
		if (decimals.length() > 0) {
			format += "." + decimals;
		}
		cellStyle.setDataFormat(df.getFormat(format));

		if (celltype.equals(CellType.TOTAL)) {
			cellStyle.setFillForegroundColor(IndexedColors.GREY_40_PERCENT.getIndex());
		}
		if (celltype.equals(CellType.CF)) {
			cellStyle.setFillForegroundColor(IndexedColors.DARK_YELLOW.getIndex());
		}
		if (celltype.equals(CellType.SUBTOTAL)) {
			cellStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
		}

		decimalFormats.put(mapPosition, cellStyle);
		return cellStyle;
	}

	private XSSFColor getThresholdColor(String measureId, Double value) {
		Color white = new Color(255, 255, 255);
		List<Threshold> thresholds = thresholdColorsMap.get(measureId);
		if (thresholds == null || thresholds.isEmpty())
			return new XSSFColor(white);
		for (Threshold t : thresholds) {
			if (t.isConstraintSatisfied(value)) {
				XSSFColor backgroundColor = t.getXSSFColor();
				return backgroundColor;
			}
		}
		return new XSSFColor(white);
	}

	public int getCalculatedFieldDecimals() {
		Integer decimals = (Integer) this.getProperty(PROPERTY_CALCULATED_FIELD_DECIMALS);
		if (decimals == null) {
			return DEFAULT_CALCULATED_FIELD_DECIMALS;
		}
		return decimals;
	}

}