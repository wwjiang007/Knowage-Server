import { IWidget } from "@/modules/documentExecution/dashboard/Dashboard"
import { IHighchartsChartModel, IHighchartsChartSerie } from "@/modules/documentExecution/dashboard/interfaces/highcharts/DashboardHighchartsWidget"

export const formatHighchartsWidgetForSave = (widget: IWidget) => {
    widget.settings.chartModel = widget.settings.chartModel.getModel()
    if (!widget.settings.chartModel) return
    removeChartData(widget.settings.chartModel)
    formatPiePlotOptions(widget.settings.chartModel)
    formatLegendSettings(widget.settings.chartModel)
    formatTooltipSettings(widget.settings.chartModel)
}

const removeChartData = (chartModel: IHighchartsChartModel) => {
    chartModel.series = []
}

const formatPiePlotOptions = (chartModel: IHighchartsChartModel) => {
    if (!chartModel.plotOptions.pie) return
    delete chartModel.plotOptions.pie.dataLabels.formatterError
}

const formatLegendSettings = (chartModel: IHighchartsChartModel) => {
    delete chartModel.legend.labelFormatterError
}

const formatTooltipSettings = (chartModel: IHighchartsChartModel) => {
    delete chartModel.tooltip.formatterError
    delete chartModel.tooltip.pointFormatterError
}