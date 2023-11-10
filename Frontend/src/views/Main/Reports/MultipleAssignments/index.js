import React, { PureComponent } from "react";
import Card from "../../../../components/Card";
import Button from "../../../../components/Button";
import SelectBox from "../../../../components/SelectBox";
import DataGrid from "./subs/DataGrid";
import { getLines } from "../../../../services/plantModel";
import { setBreadcrumbEvents } from "../../../../components/Framework/Breadcrumb/events";
import { getMultipleAssignments } from "../../../../services/reports";
import { displayPreload } from "../../../../components/Framework/Preload";
import { setIdsByClassName } from "../../../../utils";
import { Icon } from "react-fa";
import styles from "./styles.module.scss";

class MultipleAssignments extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      validationMessage: false,
      showFilters: true,
      runTime: null,
      data: [],
      lines: [],
      selected: {
        lines: [],
      },
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
    getLines().then((response) => {
      document.getElementById("btnRunReport").disabled = true;
      this.setState({ lines: response });
    });
  };

  componentDidUpdate = () => {
    setIdsByClassName([
      {
        idContainer: "sboLinesMultipleAssignments",
        tagName: "input",
        ids: ["txtSearchSboLinesMultipleAssignments"],
      },
      {
        idContainer: "sboLinesMultipleAssignments",
        tagName: "button",
        ids: ["btnSboMultipleAssignments"],
        same: true,
      },
    ]);
  };

  handlerFilters = () => {
    this.setState({ showFilters: !this.state.showFilters });
  };

  handlerReport = () => {
    const { lines } = this.state.selected;

    if (this.state.showFilters) this.handlerFilters();
    this.setState({ validationMessage: lines.length === 0 }, () => {
      if (!this.state.validationMessage) {
        displayPreload(true);
        getMultipleAssignments(lines).then((response) =>
          this.setState(
            {
              validationMessage: false,
              runTime: new Date(),
              data: response,
            },
            () => displayPreload(false)
          )
        );
      }
    });
  };

  handlerSelectBox = (values) => {
    this.setState(
      {
        selected: { lines: values },
      },
      () => {
        document.getElementById("btnRunReport").disabled =
          !this.state.selected.lines.length > 0;
      }
    );
  };

  render() {
    const { t } = this.props;
    const { validationMessage, showFilters, runTime, data, lines } = this.state;

    return (
      <React.Fragment>
        <div className={styles.container}>
          <Card
            id="crdMultipleAssignmentsFilters"
            classes={
              showFilters
                ? [styles.filters, styles.filters_opened].join(" ")
                : [styles.filters, styles.filters_closed].join(" ")
            }
            hidden={false}
            float
            flat
          >
            <SelectBox
              id="sboLinesMultipleAssignments"
              text="Production Lines"
              enableSelectAll={true}
              enableClear={true}
              store={lines}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={this.state.selected.lines}
              onChange={(values) => this.handlerSelectBox(values)}
              labelKey="LineDesc"
              valueKey="LineId"
              isLoading={false}
              height="calc(100% - 35px)"
            />
          </Card>
          <Card id="crdMultipleAssignmentsResult" autoHeight flat>
            {validationMessage ? (
              <div className={styles.validationMessage}>
                <Icon name="warning" />
                <label>
                  {t(
                    "Select the production line(s) for which you want to get the report."
                  )}
                </label>
              </div>
            ) : (
              <DataGrid t={t} runTime={runTime} data={data} />
            )}
          </Card>
        </div>
      </React.Fragment>
    );
  }
}

export default MultipleAssignments;
