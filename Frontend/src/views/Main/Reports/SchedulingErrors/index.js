import React, { PureComponent } from "react";
import Filters from "./subs/Filters";
import Card from "../../../../components/Card";
import Button from "../../../../components/Button";
import DataGrid from "./subs/DataGrid";
import { setBreadcrumbEvents } from "../../../../components/Framework/Breadcrumb/events";
import { getSchedulingErrors } from "../../../../services/reports";
import { displayPreload } from "../../../../components/Framework/Preload";
import styles from "./styles.module.scss";

class SchedulingErrors extends PureComponent {
  constructor(props) {
    super(props);

    this.refFilters = React.createRef();

    this.state = {
      validationMessage: false,
      showFilters: true,
      runTime: null,
      data: [],
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
    var filters = this.refFilters.current.state;
    const plantModel = filters.plantModel;
    var { departments, lines, units, workcells, groups } = plantModel;

    if (lines.length > 0) departments = [];
    if (units.length > 0) lines = [];
    if (workcells.length > 0) units = [];
    if (groups.length > 0) workcells = [];

    if (this.state.showFilters) this.handlerFilters();
    displayPreload(true);
    getSchedulingErrors(
      departments.join(","),
      lines.join(","),
      units.join(","),
      workcells.join(","),
      groups.join(","),
      ""
    ).then((response) =>
      this.setState(
        {
          validationMessage: false,
          runTime: new Date(),
          data: response,
        },
        () => displayPreload(false)
      )
    );
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
          <Card id="cdrSchedulingErrors" autoHeight flat>
            <DataGrid t={t} runTime={runTime} data={data} />
          </Card>
        </div>
      </React.Fragment>
    );
  }
}

export default SchedulingErrors;
