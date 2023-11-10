import React, { PureComponent } from "react";
import Filters from "./subs/Filters";
import Card from "../../../../components/Card";
import Button from "../../../../components/Button";
import DataGrid from "./subs/DataGrid";
import {
  getTasksPlantModelEditList,
  getTasksFLEditList,
} from "../../../../services/tasks";
import { setBreadcrumbEvents } from "../../../../components/Framework/Breadcrumb/events";
import { displayPreload } from "../../../../components/Framework/Preload";
import styles from "./styles.module.scss";

class TasksConfiguration extends PureComponent {
  constructor(props) {
    super(props);

    this.refFilters = React.createRef();

    this.state = {
      showFilters: true,
      runTime: null,
      data: [],
    };
  }

  componentDidMount = () => {
    const { t } = this.props;
    setBreadcrumbEvents(
      <nav>
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
      </nav>
    );
  };

  handlerFilters = () => {
    this.setState({ showFilters: !this.state.showFilters });
  };

  handlerReport = () => {
    var filters = this.refFilters.current.state;
    const { tasksConfigFilterGroup, plantModel, fl } = filters;

    displayPreload(true);
    if (this.state.showFilters) this.handlerFilters();

    if (tasksConfigFilterGroup === "Plant Model") {
      // const { departments, lines, units, workcells, groups } = plantModel;

      getTasksPlantModelEditList(plantModel.departments.join(",")).then(
        (response) => {
          response = response ?? [];
          response.forEach((row) => {
            if (row.TaskLocation !== null && row.TaskLocation !== "") {
              if (row.TaskLocation === "G") row.TaskLocation = "Global";
              if (row.TaskLocation === "L") row.TaskLocation = "Local";
            }

            if (row.Window !== null && row.Window !== "") {
              if (parseInt(row.Window) > 0) {
                let frequency = row.FrequencyType;

                if (frequency === "Shiftly" || frequency === "Daily") {
                  row.Window += " Hour".concat(
                    parseInt(row.Window) > 1 ? "s" : ""
                  );
                }

                if (frequency === "Multi-Day") {
                  row.Window += " Day".concat(
                    parseInt(row.Window) > 1 ? "s" : ""
                  );
                }

                if (frequency === "Minutes") {
                  row.Window += " Minute".concat(
                    parseInt(row.Window) > 1 ? "s" : ""
                  );
                }
              }
            }
          });

          this.setState({ data: response, runTime: new Date() }, () =>
            displayPreload(false)
          );
        }
      );
    } else {
      getTasksFLEditList(fl.fl1.join(",")).then((response) =>
        this.setState({ data: response, runTime: new Date() }, () =>
          displayPreload(false)
        )
      );
    }
  };

  render() {
    const { t } = this.props;
    const { showFilters, runTime, data } = this.state;

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
          <Card id="cdrTasksConfiguration" autoHeight flat>
            <DataGrid
              t={t}
              runTime={runTime}
              refFilters={this.refFilters.current?.state}
              data={data}
            />
          </Card>
        </div>
      </React.Fragment>
    );
  }
}

export default TasksConfiguration;
