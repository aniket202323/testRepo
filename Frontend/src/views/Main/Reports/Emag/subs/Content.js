import React, { Component } from "react";
import Card from "../../../../../components/Card";
import Popup from "../../../../../components/Popup";
import ColorCoding from "../../../../../components/ColorCoding";
import ReportPeriod from "../../../../../components/ReportPeriod";
import DataGrid from "./DataGrid";
import TrendReport from "./TrendReport";
import DowntimeDetails from "./DowntimeDetails";
import DefectDetails from "./DefectDetails";
import { displayPreload } from "../../../../../components/Framework/Preload";
import {
  getEmagTrendReport,
  getDowntimeDetails,
} from "../../../../../services/reports";
import { getEmagDefectDetails } from "../../../../../services/defects";
import dayjs from "dayjs";
import styles from "../styles.module.scss";

class Content extends Component {
  constructor(props) {
    super(props);

    this.state = {
      endDate: null,
      taskDescription: null,
      trendData: [],
      downtimeData: [],
      defectDetailsData: [],
      popTrendReport: false,
      popDowntimeDetails: false,
      popDefectDetails: false,
      trendEndDate: null,
    };
  }

  handlerTrendReportPopup = (value) => {
    // const { endDate } = this.props.filters();
    let endDate = dayjs(dayjs()).format("YYYY-MM-DD");
    let taskDescription = "";

    displayPreload(true);

    getEmagTrendReport(value.data.VarId, endDate).then((response) => {
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
      // console.log(columnsHeaderText);

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
            endDate,
            taskDescription,
            trendData: EmagData,
            popTrendReport: true,
            trendEndDate: EndReportPeriod,
          },
          () => this.state.trendData.forEach((v) => delete v.Values)
        );
      }, 500);
    });
  };

  handlerDowntimeDetails = (value) => {
    const { puId, endDate } = this.props.filters();

    displayPreload(true);
    getDowntimeDetails(
      puId,
      value.key.Component,
      dayjs(endDate).format("YYYY-MM-DD"),
      value.columnIndex
    ).then((response) => {
      this.setState(
        { downtimeData: response ?? [], popDowntimeDetails: true },
        () => displayPreload(false)
      );
    });
  };

  handlerDefectDetails = (value) => {
    displayPreload(true);
    getEmagDefectDetails(value.key.VarId, value.column.dataField).then(
      (response) => {
        this.setState(
          { defectDetailsData: response ?? [], popDefectDetails: true },
          () => displayPreload(false)
        );
      }
    );
  };

  onHidingPopup = (toolbar) => {
    this.setState({ [toolbar]: false });
  };

  render() {
    const {
      t,
      runTime,
      emagData,
      emagDowntimeData,
      startReportPeriod,
      endReportPeriod,
    } = this.props;
    const {
      trendData,
      downtimeData,
      defectDetailsData,
      popTrendReport,
      popDowntimeDetails,
      popDefectDetails,
      trendEndDate,
    } = this.state;

    return (
      <React.Fragment>
        {runTime !== null && (
          <ReportPeriod
            t={t}
            startTime={startReportPeriod}
            endTime={endReportPeriod}
            classes={styles.reportPeriod}
          />
        )}
        <Card id="crdEmag" autoHeight flat>
          <DataGrid
            t={t}
            runTime={runTime}
            data={emagData}
            handlerDowntimeDetails={this.handlerDowntimeDetails}
            handlerDefectDetails={this.handlerDefectDetails}
            handlerTrendReportPopup={this.handlerTrendReportPopup}
            view="eMag"
            from={this.props.from}
          />
          <DataGrid
            t={t}
            runTime={runTime}
            data={emagDowntimeData}
            handlerDowntimeDetails={this.handlerDowntimeDetails}
            handlerDefectDetails={this.handlerDefectDetails}
            handlerTrendReportPopup={this.handlerTrendReportPopup}
            view="downtime"
            from={this.props.from}
          />
        </Card>

        <ColorCoding
          t={t}
          report="eMag"
          visible={runTime !== null}
          classes={styles.colorCoding}
        />

        <Popup
          id="popTrendReport"
          title={t("Trend Report")}
          visible={popTrendReport}
          onHiding={this.onHidingPopup}
          resizeEnabled={false}
          dragEnabled={false}
          maxWidth="80%"
        >
          <TrendReport
            t={t}
            endDate={trendEndDate}
            taskDescription={this.state.taskDescription}
            data={trendData}
            visible={popTrendReport}
          />
        </Popup>

        <Popup
          id="popDowntimeDetails"
          title={t("Downtime Details")}
          visible={popDowntimeDetails}
          onHiding={this.onHidingPopup}
          resizeEnabled={false}
          dragEnabled={false}
          maxWidth="80%"
        >
          <DowntimeDetails
            t={t}
            data={downtimeData}
            visible={popDowntimeDetails}
          />
        </Popup>

        <Popup
          id="popDefectDetails"
          title={t("Defect Details")}
          visible={popDefectDetails}
          onHiding={this.onHidingPopup}
          resizeEnabled={false}
          dragEnabled={false}
          maxWidth="80%"
          maxHeight="350px"
        >
          <DefectDetails
            t={t}
            data={defectDetailsData}
            visible={popDefectDetails}
          />
        </Popup>
      </React.Fragment>
    );
  }
}

export default Content;
