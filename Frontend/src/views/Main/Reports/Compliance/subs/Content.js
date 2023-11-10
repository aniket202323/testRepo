import React, { Component } from "react";
import DataGrid from "./DataGrid";
import ReportPeriod from "../../../../../components/ReportPeriod";
import Popup from "../../../../../components/Popup";
import EmagReport from "../../Emag/subs/Content";
import EmagTrendReport from "../../Emag/subs/TrendReport";
import dayjs from "dayjs";
import { displayPreload } from "../../../../../components/Framework/Preload";
import {
  getEmagReportData,
  getEmagReportDowntime,
  getEmagTrendReport,
} from "../../../../../services/reports";
import { Granularity } from "../options";
import styles from "../styles.module.scss";

// Plant Model:   Site    Department   Line   Unit   Modules   Tasks
// Teams:         Team    Department   Line   Unit   Modules   Tasks
// Routes:        Route   Department   Line   Unit   Modules   Tasks

export default class Content extends Component {
  constructor(props) {
    super(props);
    this.state = {
      eMagData: [],
      eMagDTData: [],
      startReportPeriod: "",
      endReportPeriod: "",
      eMagFilters: {},
      eMagTrendTaskDescription: "",
      eMagTrendReportData: [],
      eMagTrendEndDate: "",
      popEmagReport: false,
      popEmagTrendReport: false,
    };
    this.refMainGrid = React.createRef();
    this.refMainGridFullCheck = React.createRef();
  }

  shouldComponentUpdate(nextProps, nextState) {
    if (
      nextProps.runTime !== this.props.runTime ||
      nextState.popEmagReport !== this.state.popEmagReport ||
      nextState.popEmagTrendReport !== this.state.popEmagTrendReport
    ) {
      if (nextProps.runTime !== this.props.runTime) {
        this.refMainGrid.current &&
          this.refMainGrid.current.instance.collapseAll(-1);
        this.refMainGridFullCheck.current &&
          this.refMainGridFullCheck.current.instance.collapseAll(-1);
      }
      return true;
    } else return false;
  }

  onHidingPopup = (toolbar) => {
    this.setState({ [toolbar]: false });
  };

  handlerEMagReport = (e) => {
    displayPreload(true);

    let filters = this.props.refFilters.current.state;
    let endTime = dayjs(filters.dtEndTime).format("YYYY-MM-DD");

    Promise.all([
      getEmagReportData(e.ItemId, endTime),
      getEmagReportDowntime(e.ItemId, endTime),
    ]).then((response) => {
      const [ResponseEMag, ResponseDT] = response;
      const { Dates, EmagData, StartReportPeriod, EndReportPeriod } =
        ResponseEMag;

      //Format eMag grid data
      if (EmagData.length > 0) {
        EmagData.forEach((edata) => {
          edata.Values.forEach((date) => {
            edata[
              Dates.find((t) => t.DayPosition === date.DayPosition)?.Value
            ] = date.Value;
          });
        });
      } else {
        let temp = {};

        temp.Fl4 = null;
        temp.Task = null;
        temp.TaskId = null;
        temp.Frequency = null;

        Dates.forEach((date) => (temp[date.Value] = null));
        EmagData.push(temp);
      }

      //Format DT Details grid data
      if (ResponseDT?.length > 0) {
        ResponseDT.forEach((dt) => {
          dt.Values.forEach((v) => {
            dt[
              Dates.find((date) => date.DayPosition === v.DayPosition)?.Value
            ] = v.Value !== "0" ? "7-" + v.Value : v.Value;
          });
        });
      } else {
        let temp = {};

        temp.Reason = 0;
        temp.Component = "";

        Dates.forEach((date) => (temp[date.Value] = null));
        ResponseDT.push(temp);
      }

      this.setState(
        {
          eMagData: EmagData,
          eMagDTData: ResponseDT,
          startReportPeriod: StartReportPeriod,
          endReportPeriod: EndReportPeriod,
          popEmagReport: true,
          eMagFilters: {
            puId: e.ItemId,
            endDate: dayjs(filters.dtEndTime).format("YYYY-MM-DD HH:mm:ss"),
          },
        },
        () => {
          this.state.eMagData.forEach((v) => delete v.Values);
          this.state.eMagDTData.forEach((v) => delete v.Values);
          setTimeout(() => {
            displayPreload(false);
          }, 500);
        }
      );
    });
  };

  handlerEMagTrendReport = (value) => {
    // let filters = this.props.refFilters.current.state;
    // let endDate = dayjs(filters.dtEndTime).format("YYYY-MM-DD HH:mm:ss");
    let endDate = dayjs(dayjs()).format("YYYY-MM-DD");
    let taskDescription = "";

    displayPreload(true);
    getEmagTrendReport(value.ItemId, endDate).then((response) => {
      if (response === undefined) return;
      const { Trends, EmagData, EndReportPeriod } = response;

      //This section is used to Calculate the Header text for each data column (Day on top and Month on the button)
      let columnsHeaderText = [];
      let dayValue = "";
      let monthValue = "";
      let nrbColumns = Trends.length;

      for (let i = 4; i <= 38; i++) {
        if (nrbColumns < i - 3) {
          dayValue = "";
          monthValue = "";
        } else {
          dayValue = Trends[i - 4].TrendDay.toString().padStart(2, "0");
          monthValue = Trends[i - 4].TrendMonth.toString().padStart(2, "0");
        }

        // columnsHeaderText.push(MonthValue + "-" + DayValue);
        // columnsHeaderText[42 - i] = MonthValue + "-" + DayValue;
        columnsHeaderText.push({
          DayPosition: 42 - i - 3,
          Value:
            monthValue !== "" && dayValue !== ""
              ? monthValue +
                "-" +
                dayValue +
                "-" +
                i.toString().padStart(2, "0")
              : "",
        });
      }

      columnsHeaderText.sort((a, b) => a.DayPosition - b.DayPosition);

      if (EmagData.length > 0) {
        taskDescription = EmagData[0]?.Task ?? "";

        EmagData.forEach((edata) => {
          edata.Values.forEach((date, index) => {
            let j = columnsHeaderText.find(
              (f) => f.DayPosition === date.DayPosition
            );

            if (j && j.Value !== "") edata[j.Value] = date.Value;
          });
        });
      }
      displayPreload(false);
      setTimeout(() => {
        this.setState(
          {
            eMagTrendTaskDescription: taskDescription,
            eMagTrendReportData: EmagData,
            eMagTrendEndDate: EndReportPeriod,
            popEmagTrendReport: true,
          },
          () => this.state.eMagTrendReportData.forEach((v) => delete v.Values)
        );
      }, 500);
    });
  };

  render() {
    const { t, refFilters } = this.props;
    let gridCaption = "Compliance Report - ";
    let showGrid = true;
    const {
      eMagData,
      eMagDTData,
      eMagFilters,
      startReportPeriod,
      endReportPeriod,
      eMagTrendTaskDescription,
      eMagTrendReportData,
      eMagTrendEndDate,
      popEmagReport,
      popEmagTrendReport,
    } = this.state;
    let {
      rdgGranularity,
      rdgEntryType,
      chkRouteDetails,
      chkPlantModelDetails,
      dtStartTime,
      dtEndTime,
    } = refFilters.current.state;

    let reportStartTime = dtStartTime
      ? dayjs(dtStartTime).format("YYYY-MM-DD HH:mm:ss")
      : "-";
    let reportEndTime = dtEndTime
      ? dayjs(dtEndTime).format("YYYY-MM-DD HH:mm:ss")
      : "-";

    if (rdgEntryType !== "Plant Model") rdgGranularity += 1;
    let masterDetailTemplate = null;
    let masterDetailTemplateWhenFullCheck = null;

    if (!rdgEntryType.includes("Teams")) {
      masterDetailTemplate =
        rdgGranularity === 1
          ? this.masterDetailTemplateTeam
          : rdgGranularity === 2
          ? this.masterDetailTemplateRoute
          : rdgGranularity === 3
          ? this.masterDetailTemplateDepartment
          : rdgGranularity === 4
          ? this.masterDetailTemplateLine
          : rdgGranularity === 5
          ? this.masterDetailTemplateUnit
          : rdgGranularity === 6
          ? this.masterDetailTemplateModule
          : rdgGranularity === 7
          ? this.masterDetailTemplateTask
          : undefined;
    } else {
      if (chkRouteDetails)
        masterDetailTemplate = this.masterDetailTemplateRoute;

      if (chkPlantModelDetails)
        masterDetailTemplateWhenFullCheck =
          this.masterDetailTemplateDepartmentForPlantModel;

      showGrid = !(!chkRouteDetails && chkPlantModelDetails);
    }

    gridCaption +=
      rdgEntryType.includes("Teams") && chkRouteDetails
        ? "Team/Routes"
        : rdgEntryType === "Plant Model"
        ? "" + Granularity[rdgGranularity] + " Level"
        : rdgEntryType.includes("Routes")
        ? "Route Level"
        : "";

    return (
      <React.Fragment>
        <ReportPeriod
          t={t}
          startTime={reportStartTime}
          endTime={reportEndTime}
          classes={styles.reportPeriod}
        />

        {chkRouteDetails && chkPlantModelDetails && (
          <>
            <h5 className={styles.gridCaptions}>
              {t("Compliance Report - Team Summary")}
            </h5>
            <DataGrid
              t={this.props.t}
              detailData={null}
              runTime={this.props.runTime}
              refFilters={this.props.refFilters}
              caption={t("Team")}
              isTeamsSummary={true}
            ></DataGrid>
          </>
        )}

        {showGrid && (
          <>
            <h5 className={styles.gridCaptions}>{t(gridCaption)}</h5>
            <DataGrid
              t={this.props.t}
              reference={this.refMainGrid}
              detailData={null}
              runTime={this.props.runTime}
              refFilters={this.props.refFilters}
              caption={
                Granularity[
                  rdgEntryType !== "Plant Model"
                    ? rdgGranularity - 1
                    : rdgGranularity
                ]
              }
              masterDetailTemplate={masterDetailTemplate}
            ></DataGrid>
          </>
        )}

        {chkPlantModelDetails && (
          <>
            <h5 className={styles.gridCaptions}>
              {t("Compliance Report - Team/Plant model")}
            </h5>
            <DataGrid
              t={this.props.t}
              reference={this.refMainGridFullCheck}
              detailData={null}
              runTime={this.props.runTime}
              refFilters={this.props.refFilters}
              caption={
                Granularity[
                  rdgEntryType !== "Plant Model"
                    ? rdgGranularity - 1
                    : rdgGranularity
                ]
              }
              isTeamsPlantModel={true}
              masterDetailTemplate={masterDetailTemplateWhenFullCheck}
            ></DataGrid>
          </>
        )}

        {/* eMag Report */}
        <Popup
          id="popEmagReport"
          title={t("eMag Report")}
          resizeEnabled={false}
          dragEnabled={false}
          maxWidth="80%"
          height="80%"
          visible={popEmagReport}
          onHiding={this.onHidingPopup}
        >
          <div className={styles.eMagReportContainer}>
            <EmagReport
              t={t}
              from="compliance"
              runTime={new Date()}
              emagData={eMagData}
              emagDowntimeData={eMagDTData}
              startReportPeriod={startReportPeriod}
              endReportPeriod={endReportPeriod}
              filters={() => {
                return eMagFilters;
              }}
            />
          </div>
        </Popup>

        {/* eMag Trend Report */}
        <Popup
          id="popEmagTrendReport"
          title={t("Trend Report")}
          resizeEnabled={false}
          dragEnabled={false}
          maxWidth="80%"
          visible={popEmagTrendReport}
          onHiding={this.onHidingPopup}
        >
          <EmagTrendReport
            t={t}
            endDate={eMagTrendEndDate}
            taskDescription={eMagTrendTaskDescription}
            data={eMagTrendReportData}
            visible={popEmagTrendReport}
          />
        </Popup>
      </React.Fragment>
    );
  }

  masterDetailTemplateTeam = (e) => {
    return (
      <DataGrid
        t={this.props.t}
        detailData={e.data.data}
        refFilters={this.props.refFilters}
        caption="Team"
        masterDetailTemplate={this.masterDetailTemplateRoute}
      />
    );
  };

  masterDetailTemplateRoute = (e) => {
    return (
      <DataGrid
        t={this.props.t}
        detailData={e.data.data}
        refFilters={this.props.refFilters}
        caption="Route"
        isRouteMasterDetail={true}
        masterDetailTemplate={this.masterDetailTemplateDepartment}
      />
    );
  };

  masterDetailTemplateDepartment = (e) => {
    return (
      <DataGrid
        t={this.props.t}
        detailData={e.data.data}
        refFilters={this.props.refFilters}
        caption="Department"
        masterDetailTemplate={this.masterDetailTemplateLine}
      />
    );
  };

  masterDetailTemplateDepartmentForPlantModel = (e) => {
    return (
      <DataGrid
        t={this.props.t}
        detailData={e.data.data}
        refFilters={this.props.refFilters}
        caption="Department"
        isDepartmentMasterDetail={false}
        masterDetailTemplate={this.masterDetailTemplateLine}
      />
    );
  };

  masterDetailTemplateLine = (e) => {
    return (
      <DataGrid
        t={this.props.t}
        detailData={e.data.data}
        refFilters={this.props.refFilters}
        caption="Line"
        masterDetailTemplate={this.masterDetailTemplateUnit}
      />
    );
  };

  masterDetailTemplateUnit = (e) => {
    return (
      <DataGrid
        t={this.props.t}
        detailData={e.data.data}
        refFilters={this.props.refFilters}
        caption="Primary Unit"
        masterDetailTemplate={this.masterDetailTemplateModule}
      />
    );
  };

  masterDetailTemplateModule = (e) => {
    return (
      <DataGrid
        t={this.props.t}
        detailData={e.data.data}
        refFilters={this.props.refFilters}
        caption="Module"
        masterDetailTemplate={this.masterDetailTemplateTask}
        handlerEMagReport={this.handlerEMagReport}
      />
    );
  };

  masterDetailTemplateTask = (e) => {
    return (
      <DataGrid
        t={this.props.t}
        detailData={e.data.data}
        refFilters={this.props.refFilters}
        caption="Task"
        handlerEMagTrendReport={this.handlerEMagTrendReport}
      />
    );
  };
}
