import React, { Component } from "react";
import DxDataGrid, {
  Column,
  Summary,
  GroupItem,
  Export,
} from "devextreme-react/ui/data-grid";
import DataGrid from "../DataGrid";
import {
  getCompliancePrint,
  getComplianceSpecs,
} from "../../../../../../services/reports";
import { Granularity, CILResultSpec } from "../../options";
import { displayPreload } from "../../../../../../components/Framework/Preload";
import Button from "../../../../../../components/Button";
import { exportDataGrid } from "devextreme/excel_exporter";
import ExcelJS from "exceljs";
import saveAs from "file-saver";
import ReportPeriod from "../../../../../../components/ReportPeriod";
import icons from "../../../../../../resources/icons";
import dayjs from "dayjs";
import styles from "../../styles.module.scss";

export default class Content extends Component {
  constructor(props) {
    super(props);
    this.refPrintGrid = React.createRef();
    this.refPrintPlantModelGrid = React.createRef();
    this.refSummaryGrid = React.createRef();

    this.state = {
      data: null,
      dataPlantModel: null,
      specs: [],
      startTime: "",
      endTime: "",
    };
  }

  componentDidMount = () => {
    this.getPrintData();
    if (this.isTeamPlantModelChecked()) this.getPrintData(true);
  };

  componentDidUpdate = (prevProps, prevState) => {
    if (this.props.runTime !== prevProps.runTime) {
      this.getPrintData();
      if (this.isTeamPlantModelChecked()) this.getPrintData(true);
    }
  };

  isPlantModel = () => {
    return this.props.refFilters.current.state.rdgEntryType === "Plant Model";
  };

  isTeamBothChecked = () => {
    let { rdgEntryType, chkRouteDetails, chkPlantModelDetails } =
      this.props.refFilters.current.state;

    return (
      rdgEntryType.includes("Teams") && chkRouteDetails && chkPlantModelDetails
    );
  };

  isTeamPlantModelChecked = () => {
    let { rdgEntryType, chkPlantModelDetails } =
      this.props.refFilters.current.state;

    return rdgEntryType.includes("Teams") && chkPlantModelDetails;
  };

  isOnlyPlantModelChecked = () => {
    let { rdgEntryType, chkRouteDetails, chkPlantModelDetails } =
      this.props.refFilters.current.state;

    return (
      rdgEntryType.includes("Teams") && !chkRouteDetails && chkPlantModelDetails
    );
  };

  getPrintData = (isTeamBothChecked = false) => {
    displayPreload(true);

    let filters = this.props.refFilters.current.state;

    let topLevelId = 0;
    let selectionItemId = 0;
    let teamsIds = "";
    let routesIds = "";
    let granularity = filters.rdgGranularity;

    if (granularity > 3) {
      const { departments, lines, units } = filters.plantModel;

      topLevelId =
        granularity === 4
          ? departments.toString()
          : granularity === 5
          ? lines.toString()
          : granularity === 6
          ? units.toString()
          : 0;
    } else {
      let { plantModel } = filters;

      routesIds =
        filters.rdgEntryType === "My Routes"
          ? plantModel.myroutes.join(",")
          : plantModel.routes.join(",");

      teamsIds =
        filters.rdgEntryType === "My Teams"
          ? plantModel.myteams.join(",")
          : plantModel.teams.join(",");
    }

    let params = {};

    params.granularity = granularity;
    params.topLevelId = topLevelId;
    params.subLevel = selectionItemId !== 0 ? 1 : 0;
    params.startTime = dayjs(filters.dtStartTime).format("YYYY-MM-DD HH:mm:ss");
    params.endTime = dayjs(filters.dtEndTime).format("YYYY-MM-DD HH:mm:ss");
    params.routeIds = routesIds;
    params.teamIds = teamsIds;
    params.teamDetails = isTeamBothChecked ? 4 : granularity > 3 ? 0 : 2;
    params.qFactorOnly = filters.chkQFactor;
    params.selectionItemId = selectionItemId;
    params.HSEOnly = filters.HSETasks;
    // params.MinimumUptimeOnly = filters.chkMinimumUptime;

    getCompliancePrint(params).then((data) => {
      data = data ?? [];
      getComplianceSpecs(
        granularity,
        data.map((x) => x.ItemId).join(","),
        params.startTime,
        params.endTime
      ).then((specs) => {
        if (!isTeamBothChecked)
          this.setState(
            {
              data,
              specs,
              startTime: params.startTime,
              endTime: params.endTime,
            },
            () => displayPreload(false)
          );
        else if (isTeamBothChecked || this.isOnlyPlantModelChecked())
          // TEAMS / PLANT MODEL
          this.setState(
            {
              dataPlantModel: data,
              specs,
              startTime: params.startTime,
              endTime: params.endTime,
            },
            () => displayPreload(false)
          );
      });
    });
  };

  onCellPrepared = (e) => {
    let specs = this.state.specs;

    let cells = [
      "DoneLate",
      "NumberMissed",
      "PctDone",
      "DefectsFound",
      "OpenDefects",
    ];

    if (e.rowType === "data") {
      if (specs !== null && specs?.length > 0) {
        let data = e.data[e.column.dataField];
        let elem = e.cellElement;

        if (cells.includes(e.column.dataField)) {
          let caption = CILResultSpec[e.column.dataField];
          elem.classList.add(this.getCellColor(data, caption));
        }
      }
    } else if (e.rowType === "group") {
      if (e.summaryItems) {
        let si = e.summaryItems.find((i) => cells.includes(i.column));
        if (si && specs !== null && specs?.length > 0) {
          let elem = e.cellElement;
          let caption = CILResultSpec[si.column];
          elem.classList.add(this.getCellColor(si.value, caption));
        }
      }
    }
  };

  getCellColor = (value, caption) => {
    let specs = this.state.specs;
    let spec = specs?.find((x) => x.SpecName === caption);

    //  'Evaluate Lower Reject Limit
    if (parseFloat(value) < parseFloat(spec.Lr)) {
      return styles.grdLowerReject;
    }
    // 'Evaluate Lower Warning Limit
    else if (parseFloat(value) < parseFloat(spec.Lw)) {
      return styles.grdLowerWarning;
    }
    // 'Evaluate Lower User Limit
    else if (parseFloat(value) < parseInt(spec.Lu)) {
      return styles.grdLowerUser;
    }
    // 'Evaluate Upper Reject Limit
    else if (parseFloat(value) > parseInt(spec.Ur)) {
      return styles.grdUpperReject;
    }
    // Evaluate Upper Warning Limit
    else if (parseFloat(value) > parseInt(spec.Uw)) {
      return styles.grdUpperWarning;
    }
    // 'Evaluate Upper User Limit
    else if (parseFloat(value) > parseInt(spec.Uu)) {
      return styles.grdUpperUser;
    } else return null;
  };

  customizeCell = (options) => {
    const { gridCell, excelCell } = options;
    let specs = this.state.specs;

    if (!gridCell) {
      return;
    }

    let cells = [
      "DoneLate",
      "NumberMissed",
      "PctDone",
      "DefectsFound",
      "OpenDefects",
    ];

    if (gridCell.rowType === "data" || gridCell.rowType === "group") {
      if (specs !== null && specs.length > 0) {
        if (cells.includes(gridCell.column.dataField)) {
          let specs = this.state.specs;
          let spec = specs?.find(
            (x) => x.SpecName === CILResultSpec[gridCell.column.dataField]
          );

          excelCell.font = { bold: false };

          let summary =
            gridCell.rowType === "group"
              ? [...gridCell.groupSummaryItems].pop()
              : null;
          let value = summary !== null ? summary?.value ?? 0 : gridCell.value;

          //  'Evaluate Lower Reject Limit
          if (parseFloat(value) < parseFloat(spec.Lr)) {
            excelCell.fill = {
              type: "pattern",
              pattern: "solid",
              fgColor: { argb: "dc143c" },
            };
            excelCell.font = { color: { argb: "ffffff" } };
          }
          // 'Evaluate Lower Warning Limit
          else if (parseFloat(value) < parseFloat(spec.Lw)) {
            excelCell.fill = {
              type: "pattern",
              pattern: "solid",
              fgColor: { argb: "ffa500" },
            };
            excelCell.font = { color: { argb: "000000" } };
          }
          // 'Evaluate Lower User Limit
          else if (parseFloat(value) < parseInt(spec.Lu)) {
            excelCell.fill = {
              type: "pattern",
              pattern: "solid",
              fgColor: { argb: "ffff00" },
            };
            excelCell.font = { color: { argb: "000000" } };
          }
          // 'Evaluate Upper Reject Limit
          else if (parseFloat(value) > parseInt(spec.Ur)) {
            excelCell.fill = {
              type: "pattern",
              pattern: "solid",
              fgColor: { argb: "dc143c" },
            };
            excelCell.font = { color: { argb: "ffffff" } };
          }
          // Evaluate Upper Warning Limit
          else if (parseFloat(value) > parseInt(spec.Uw)) {
            excelCell.fill = {
              type: "pattern",
              pattern: "solid",
              fgColor: { argb: "ffa500" },
            };
            excelCell.font = { color: { argb: "000000" } };
          }
          // 'Evaluate Upper User Limit
          else if (parseFloat(value) > parseInt(spec.Uu)) {
            excelCell.fill = {
              type: "pattern",
              pattern: "solid",
              fgColor: { argb: "ffff00" },
            };
            excelCell.font = { color: { argb: "000000" } };
          }
        }
      }
      if (
        gridCell.column.dataField === "TotalCount" ||
        gridCell.column.dataField === "OnTime" ||
        gridCell.column.dataField === "TaskDueLate"
      ) {
        excelCell.font = { bold: false };
      }
    }
  };

  calculateCustomSummary(options) {
    if (options.name === "PctDoneSummary") {
      if (options.summaryProcess === "start") {
        options.totalValue = 0;
        options.sumTotalCount = 0;
        options.sumTaskDueLate = 0;
        options.sumNumberMissed = 0;
      } else if (options.summaryProcess === "calculate") {
        const { TotalCount, TaskDueLate, NumberMissed } = options.value;

        options.sumTotalCount = options.sumTotalCount + TotalCount;
        options.sumTaskDueLate = options.sumTaskDueLate + TaskDueLate;
        options.sumNumberMissed = options.sumNumberMissed + NumberMissed;
      } else if (options.summaryProcess === "finalize") {
        const { sumTotalCount, sumTaskDueLate, sumNumberMissed } = options;

        let sumTaskCount = sumTotalCount + sumTaskDueLate;
        let diff = sumTaskCount - sumTaskDueLate;

        let total = ((diff - sumNumberMissed) / diff) * 100;

        options.totalValue =
          sumTaskCount - sumTaskDueLate !== 0
            ? total !== 0
              ? total.toFixed(1)
              : 0
            : 0;
      }
    }
  }

  onExporting = (e) => {
    const { t } = this.props;
    let { rdgGranularity, rdgEntryType, chkRouteDetails } =
      this.props.refFilters.current?.state;
    let { data, dataPlantModel } = this.state;
    let gridCaption =
      rdgEntryType.includes("Teams") && chkRouteDetails
        ? "Team Routes"
        : rdgEntryType === "Plant Model"
        ? "" + Granularity[rdgGranularity] + " Level"
        : rdgEntryType.includes("Routes")
        ? "Route Level"
        : "";

    let isTeamBothChecked = this.isTeamBothChecked();
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet(
      isTeamBothChecked ? t("Team Summary") : t(gridCaption)
    );

    exportDataGrid({
      component: isTeamBothChecked
        ? this.refSummaryGrid.current?.instance
        : !this.isOnlyPlantModelChecked()
        ? this.refPrintGrid.current?.instance
        : this.refPrintPlantModelGrid.current?.instance,
      worksheet: worksheet,
      customizeCell: this.customizeCell,
    })
      .then(() => {
        this.cellReportPeriod(worksheet);

        if (isTeamBothChecked) {
          if (data?.length)
            return exportDataGrid({
              component: this.refPrintGrid.current?.instance,
              worksheet: workbook.addWorksheet(t("Team Routes")),
              customizeCell: this.customizeCell,
            }).then(() => {
              if (dataPlantModel?.length)
                return exportDataGrid({
                  component: this.refPrintPlantModelGrid.current?.instance,
                  worksheet: workbook.addWorksheet(t("Team Plant model")),
                  customizeCell: this.customizeCell,
                });
            });
        }

        if (isTeamBothChecked && !this.isOnlyPlantModelChecked())
          return exportDataGrid({
            component: this.refPrintPlantModelGrid.current?.instance,
            worksheet: workbook.addWorksheet(
              data?.length === 0 ? t("Team Plant model") : t("Team Routes")
            ),
            customizeCell: this.customizeCell,
          });
      })
      .then(() => {
        workbook.xlsx.writeBuffer().then(function (buffer) {
          saveAs(
            new Blob([buffer], { type: "application/octet-stream" }),
            "CompliancePrintingXtraReport.xlsx"
          );
        });
      });

    e.cancel = true;
  };

  cellReportPeriod = (worksheet) => {
    const { t } = this.props;
    const { startTime, endTime } = this.state;
    worksheet.insertRow(1);
    let cellReportPeriod = worksheet.getRow(1);
    cellReportPeriod.getCell(1).value = {
      richText: [
        { font: { bold: true }, text: `${t("Report Period")}: ` },
        {
          font: { bold: false },
          text: startTime
            ? dayjs(startTime).format("YYYY-MM-DD HH:mm:ss")
            : "-",
        },
        { font: { bold: true }, text: " To " },
        {
          font: { bold: false },
          text: endTime ? dayjs(endTime).format("YYYY-MM-DD HH:mm:ss") : "-",
        },
      ],
    };
  };

  getDataGrid = (isTeamsPlantModel = false) => {
    let { t, refFilters } = this.props;
    let filters = refFilters.current.state;
    let { data, dataPlantModel } = this.state;
    let granularity = filters.rdgGranularity;
    return (
      <DxDataGrid
        id="grdCILResultPrint"
        ref={
          isTeamsPlantModel ? this.refPrintPlantModelGrid : this.refPrintGrid
        }
        dataSource={isTeamsPlantModel ? dataPlantModel : data}
        groupPanel={{ visible: false }}
        columnChooser={{ enabled: false }}
        paging={{ enabled: false }}
        height={
          this.isTeamBothChecked() ? "calc(50% - 160px)" : "calc(100% - 150px)"
        }
        onCellPrepared={this.onCellPrepared}
        onExporting={this.onExporting}
      >
        <Column
          dataField="ItemDesc"
          caption={t("Team")}
          visible={granularity === 1}
          groupIndex={granularity === 1 ? 0 : null}
          groupCellTemplate={(elem, data) => {
            elem.append(data.displayValue);
          }}
        />
        {!isTeamsPlantModel && !this.isPlantModel() && (
          <Column
            dataField={
              isTeamsPlantModel
                ? null
                : granularity === 2
                ? "ItemDesc"
                : "RouteDesc"
            }
            caption={""}
            // caption={t("Route")}
            visible={!isTeamsPlantModel || granularity <= 2}
            groupIndex={isTeamsPlantModel ? null : granularity <= 2 ? 0 : null}
            groupCellTemplate={(elem, data) => {
              elem.append(data.displayValue);
            }}
          />
        )}
        <Column
          dataField="ItemDesc"
          caption={t("Site")}
          visible={granularity === 3}
          groupIndex={granularity === 3 ? 0 : null}
          groupCellTemplate={(elem, data) => {
            elem.append(data.displayValue);
          }}
        />
        <Column
          dataField="DeptDesc"
          caption={t("Department")}
          visible={granularity <= 4}
          groupIndex={granularity <= 4 ? 0 : null}
          groupCellTemplate={(elem, data) => {
            elem.append(data.displayValue);
          }}
        />
        <Column
          dataField="PlDesc"
          caption={t("Line")}
          visible={granularity <= 5}
          groupIndex={granularity <= 5 ? 1 : null}
          groupCellTemplate={(elem, data) => {
            elem.append(data.displayValue);
          }}
        />
        <Column
          dataField="MasterDesc"
          caption={t("Primary Unit")}
          visible={true}
          groupIndex={2}
          groupCellTemplate={(elem, data) => {
            elem.append(data.displayValue);
          }}
        />
        <Column
          dataField="SlaveDesc"
          caption={t("Module")}
          visible={true}
          groupIndex={3}
          groupCellTemplate={(elem, data) => {
            elem.append(data.displayValue);
          }}
        />
        <Column dataField="VarDesc" caption="" />
        <Column dataField="Fl3" caption={t("FL3")} width="50px" />
        <Column dataField="Fl4" caption={t("FL4")} width="50px" />
        <Column dataField="TotalCount" width="80px" />
        <Column dataField="OnTime" width="80px" />
        <Column dataField="DoneLate" width="80px" />
        <Column dataField="NumberMissed" caption={t("Missed")} width="80px" />
        <Column
          dataField="TaskDueLate"
          caption={t("Due (Late)")}
          width="80px"
        />
        <Column dataField="PctDone" caption={t("% Done")} width="80px" />
        <Column dataField="DefectsFound" width="100px" />
        <Column
          dataField="OpenDefects"
          caption={t("Opened Defects")}
          width="100px"
        />
        <Summary calculateCustomSummary={this.calculateCustomSummary}>
          <GroupItem
            column="TotalCount"
            summaryType="sum"
            showInColumn="TotalCount"
            displayFormat="{0}"
            alignByColumn={true}
          />
          <GroupItem
            column="OnTime"
            summaryType="sum"
            showInColumn="OnTime"
            displayFormat="{0}"
            alignByColumn={true}
          />
          <GroupItem
            column="DoneLate"
            summaryType="sum"
            showInColumn="DoneLate"
            displayFormat="{0}"
            alignByColumn={true}
          />
          <GroupItem
            column="NumberMissed"
            summaryType="sum"
            showInColumn="NumberMissed"
            displayFormat="{0}"
            alignByColumn={true}
          />
          <GroupItem
            column="TaskDueLate"
            summaryType="sum"
            showInColumn="TaskDueLate"
            displayFormat="{0}"
            alignByColumn={true}
          />
          {/* <GroupItem
              column="PctDone"
              summaryType="avg"
              showInColumn="PctDone"
              displayFormat="{0}"
              alignByColumn={true}
              customizeText={(summary) =>
                summary.value > 0
                  ? Number.parseFloat(summary.value).toFixed(1)
                  : 0
              }
            /> */}
          <GroupItem
            name="PctDoneSummary"
            // column="PctDone"
            summaryType="custom"
            showInColumn="PctDone"
            displayFormat="{0}"
            alignByColumn={true}
          />
          <GroupItem
            column="DefectsFound"
            summaryType="sum"
            showInColumn="DefectsFound"
            displayFormat="{0}"
            alignByColumn={true}
          />
          <GroupItem
            column="OpenDefects"
            summaryType="sum"
            showInColumn="OpenDefects"
            displayFormat="{0}"
            alignByColumn={true}
          />
        </Summary>
        <Export
          enabled={false}
          // fileName="CompliancePrintingXtraReport"
          // customizeExcelCell={this.customizeExcelCell}
        />
      </DxDataGrid>
    );
  };

  render() {
    const { t, refFilters } = this.props;
    let { data, dataPlantModel, startTime, endTime } = this.state;

    let gridCaption = "Compliance Report - ";
    let filters = refFilters.current.state;
    let granularity = filters.rdgGranularity;
    let { rdgEntryType, chkRouteDetails, chkPlantModelDetails } = filters;

    let isTeamBothChecked =
      rdgEntryType.includes("Teams") && chkRouteDetails && chkPlantModelDetails;

    gridCaption +=
      rdgEntryType.includes("Teams") && chkRouteDetails
        ? "Team/Routes"
        : rdgEntryType === "Plant Model"
        ? "" + Granularity[granularity] + " Level"
        : rdgEntryType.includes("Routes")
        ? "Route Level"
        : "";

    let reportStartTime = startTime
      ? dayjs(startTime).format("YYYY-MM-DD HH:mm:ss")
      : "-";
    let reportEndTime = endTime
      ? dayjs(endTime).format("YYYY-MM-DD HH:mm:ss")
      : "-";

    // if (data?.length === 0) return (
    //   <div className={styles.noDataMessage}>
    //     <img alt="" src={icons.info} />
    //     <label>
    //       {t("No data to display for the current selection.")}
    //     </label>
    //   </div>
    // )

    return (
      <React.Fragment>
        <div className={styles.butttonCommand}>
          <Button
            id="btnPrintReport"
            hint={t("Print Report")}
            classes={styles.buttons}
            imgsrc={icons.print}
            onClick={() => window.print()}
          />
          <Button
            id="btnExcelReport"
            hint={t("Export to Excel")}
            classes={styles.buttons}
            imgsrc={icons.excel}
            onClick={() => {
              let grid =
                !this.isOnlyPlantModelChecked() && data?.length
                  ? this.refPrintGrid.current?.instance
                  : this.refPrintPlantModelGrid.current?.instance;
              grid && grid.exportToExcel(false);
            }}
          />
        </div>

        <ReportPeriod
          t={t}
          startTime={reportStartTime}
          endTime={reportEndTime}
        />

        {isTeamBothChecked && (
          <>
            <h5 className={styles.gridCaptions}>
              {t("Compliance Report - Team Summary")}
            </h5>
            <DataGrid
              t={this.props.t}
              reference={this.refSummaryGrid}
              detailData={null}
              runTime={this.props.runTime}
              refFilters={this.props.refFilters}
              // caption={t("Team")}
              isTeamsSummary={true}
            ></DataGrid>
          </>
        )}
        {!this.isOnlyPlantModelChecked() && data?.length ? (
          <>
            <h5 className={styles.gridCaptionsPrint}>{t(gridCaption)}</h5>
            {this.getDataGrid()}
          </>
        ) : (
          <></>
        )}
        {this.isTeamPlantModelChecked() && dataPlantModel?.length ? (
          <>
            <h5 className={styles.gridCaptionsPrint}>
              {t("Compliance Report - Team/Plant model")}
            </h5>
            {this.getDataGrid(true)}
          </>
        ) : (
          <></>
        )}
      </React.Fragment>
    );
  }
}
