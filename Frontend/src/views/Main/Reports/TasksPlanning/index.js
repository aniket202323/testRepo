import React, { PureComponent } from "react";
import Filters from "./subs/Filters";
import Card from "../../../../components/Card";
import Button from "../../../../components/Button";
import DataGrid from "./subs/DataGrid";
import { setBreadcrumbEvents } from "../../../../components/Framework/Breadcrumb/events";
import { getTasksPlanning } from "../../../../services/reports";
import { displayPreload } from "../../../../components/Framework/Preload";
import ReportPeriod from "../../../../components/ReportPeriod";
import dayjs from "dayjs";
import styles from "./styles.module.scss";

class TasksPlanning extends PureComponent {
  constructor(props) {
    super(props);

    this.refFilters = React.createRef();

    this.state = {
      showFilters: true,
      runTime: null,
      data: [],
      startTime: "",
      endTime: "",
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
    this.setState({ showFilters: !this.state.showFilters });
  };

  handlerReport = () => {
    displayPreload(true);
    if (this.state.showFilters) this.handlerFilters();

    var filters = this.refFilters.current.state;
    const { plantModel } = filters;

    let granularity,
      topLevelId,
      startTime,
      endTime,
      routesIds,
      teamsIds,
      teamsDetails,
      departments,
      lines,
      units;

    //granularity
    granularity = filters.rdgGranularity;

    //topLevelId
    topLevelId = 0;
    if (granularity === 4) {
      topLevelId = plantModel.departments.join();
    }

    if (granularity === 5) {
      topLevelId = plantModel.lines.join();
    }

    if (granularity === 6) {
      topLevelId = plantModel.units.join();
    }

    //routesIds
    routesIds =
      filters.rdgEntryType === "My Routes"
        ? plantModel.myroutes.join(",")
        : plantModel.routes.join(",");

    //teamsIds
    teamsIds =
      filters.rdgEntryType === "My Teams"
        ? plantModel.myteams.join(",")
        : plantModel.teams.join(",");

    //start and endtime
    startTime = dayjs(filters.dtStartTime).format("YYYY-MM-DD HH:mm:ss");
    endTime = dayjs(filters.dtEndTime).format("YYYY-MM-DD HH:mm:ss");

    //teamsDetails
    teamsDetails = filters.rdgTeamsDetails;

    //departments
    departments = filters.departments
      .filter((t) => plantModel.departments.find((x) => x === t.DeptId))
      .map((m) => m.DeptDesc)
      .join(",");

    //lines
    lines = filters.lines
      .filter((t) => plantModel.lines.find((x) => x === t.LineId))
      .map((m) => m.LineDesc)
      .join(",");

    //units
    units = filters.units
      .filter((t) => plantModel.units.find((x) => x === t.MasterId))
      .map((m) => m.MasterDesc)
      .join(",");

    getTasksPlanning(
      granularity,
      topLevelId,
      startTime,
      endTime,
      routesIds,
      teamsIds,
      teamsDetails,
      departments,
      lines,
      units
    ).then((response) => {
      this.setState(
        { data: response ?? [], runTime: new Date(), startTime, endTime },
        () => displayPreload(false)
      );
    });
  };

  render() {
    const { t } = this.props;
    const { showFilters, runTime, data, startTime, endTime } = this.state;

    return (
      <React.Fragment>
        <div className={styles.container}>
          <Card
            id="cdrFilters"
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
          <Card id="cdrTasksPlaning" autoHeight flat>
            {runTime !== null && (
              <ReportPeriod t={t} startTime={startTime} endTime={endTime} />
            )}
            <DataGrid
              t={t}
              runTime={runTime}
              refFilters={this.refFilters.current?.state}
              data={data}
              hideInfoDetail={styles.infoDetailGrid}
            />
          </Card>
        </div>
      </React.Fragment>
    );
  }
}

export default TasksPlanning;
