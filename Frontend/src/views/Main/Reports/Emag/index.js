import React, { PureComponent } from "react";
import Filters from "./subs/Filters";
import Card from "../../../../components/Card";
import Button from "../../../../components/Button";
import Content from "./subs/Content";
import { setBreadcrumbEvents } from "../../../../components/Framework/Breadcrumb/events";
import {
  getEmagReportData,
  getEmagReportDowntime,
} from "../../../../services/reports";
import { displayPreload } from "../../../../components/Framework/Preload";
import dayjs from "dayjs";
import styles from "./styles.module.scss";

class Emag extends PureComponent {
  constructor(props) {
    super(props);

    this.refFilters = React.createRef();

    this.state = {
      showFilters: true,
      runTime: null,
      emagData: [],
      emagDowntimeData: [],
      startDate: "",
      endDate: "",
      startReportPeriod: "",
      endReportPeriod: "",
    };
  }

  componentDidMount = () => {
    const { t } = this.props;
    setBreadcrumbEvents(
      <nav>
        <Button
          id="btnFilters"
          icon="filter"
          hint={t("Show/Hide Filters")}
          primary
          classes={styles.breadcrumbButton}
          onClick={this.handlerFilters}
        />
        <Button
          id="btnRunReport"
          icon="rocket"
          hint={t("Run Report")}
          primary
          disabled={false}
          classes={styles.breadcrumbButton}
          onClick={this.handlerReport}
        />
      </nav>
    );
  };

  handlerFilters = () => {
    this.setState({
      showFilters: !this.state.showFilters,
    });
  };

  handlerReport = () => {
    var filters = this.refFilters.current.state;
    const { workcells } = filters.plantModel;
    const { endDate } = filters;

    if (this.state.showFilters) this.handlerFilters();
    displayPreload(true);

    Promise.all([
      getEmagReportData(
        workcells.join(","),
        dayjs(endDate).format("YYYY-MM-DD")
      ),
      getEmagReportDowntime(
        workcells.join(","),
        dayjs(endDate).format("YYYY-MM-DD")
      ),
    ]).then((response) => {
      const [ResponseEMag, ResponseDT] = response;
      const {
        Dates,
        EmagData,
        StartReportPeriod,
        EndReportPeriod,
      } = ResponseEMag;

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
          runTime: new Date(),
          emagData: EmagData,
          emagDowntimeData: ResponseDT,
          startDate: this.refFilters.current.state.startDate,
          endDate: this.refFilters.current.state.endDate,
          startReportPeriod: StartReportPeriod,
          endReportPeriod: EndReportPeriod,
        },
        () => {
          this.state.emagData.forEach((v) => delete v.Values);
          this.state.emagDowntimeData.forEach((v) => delete v.Values);
          setTimeout(() => {
            displayPreload(false);
          }, 500);
        }
      );
    });
  };

  render() {
    const { t } = this.props;
    const {
      showFilters,
      runTime,
      emagData,
      emagDowntimeData,
      startReportPeriod,
      endReportPeriod,
    } = this.state;

    return (
      <React.Fragment>
        <div className={styles.container}>
          <Card
            id="crdFilters"
            classes={
              showFilters
                ? [styles.filters, styles.filters_opened].join(" ")
                : [styles.filters, styles.filters_closed].join(" ")
            }
            hidden={false}
            float
            flat
          >
            <Filters t={t} ref={this.refFilters} />
          </Card>

          <Content
            t={t}
            from="eMag"
            runTime={runTime}
            emagData={emagData}
            emagDowntimeData={emagDowntimeData}
            startReportPeriod={startReportPeriod}
            endReportPeriod={endReportPeriod}
            filters={() => {
              const filters = this.refFilters.current?.state;

              return {
                puId: filters?.plantModel.workcells.join(","),
                endDate: filters?.endDate,
              };
            }}
          />
        </div>
      </React.Fragment>
    );
  }
}

export default Emag;
