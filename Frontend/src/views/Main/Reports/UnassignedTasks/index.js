import React, { PureComponent } from "react";
import Card from "../../../../components/Card";
import Button from "../../../../components/Button";
import SelectBox from "../../../../components/SelectBox";
import CheckBox from "../../../../components/CheckBox";
import DataGrid from "./subs/DataGrid";
import { getLines } from "../../../../services/plantModel";
import { setBreadcrumbEvents } from "../../../../components/Framework/Breadcrumb/events";
import { getUnassignedTasks } from "../../../../services/reports";
import { displayPreload } from "../../../../components/Framework/Preload";
import { setIdsByClassName } from "../../../../utils";
import { Icon } from "react-fa";
import icons from "../../../../resources/icons";
import styles from "./styles.module.scss";

class UnassignedTasks extends PureComponent {
  constructor(props) {
    super(props);

    this.refGrid = React.createRef();

    this.state = {
      validationMessage: false,
      showFilters: true,
      runTime: null,
      data: [],
      lines: [],
      selected: {
        routeFlag: false,
        teamFlag: false,
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
          classes={styles.breadcrumbButton}
          onClick={this.handlerReport}
          disabled={false}
        />
      </nav>
    );

    displayPreload(true);
    getLines().then((response) => {
      this.setState({ lines: response }, () => {
        document.getElementById("btnRunReport").disabled = true;
        displayPreload(false);
      });
    });
  };

  componentDidUpdate = () => {
    setIdsByClassName([
      {
        idContainer: "sboLinesUnassignedTasks",
        tagName: "input",
        ids: ["txtSearchSboLinesUnassignedTasks"],
      },
      {
        idContainer: "sboLinesUnassignedTasks",
        tagName: "button",
        ids: ["btnSboUnassignedTasks"],
        same: true,
      },
    ]);
  };

  handlerReport = () => {
    const { lines, routeFlag, teamFlag } = this.state.selected;

    if (this.state.showFilters) this.handlerFilters();
    this.setState({ validationMessage: !routeFlag && !teamFlag }, () => {
      if (!this.state.validationMessage) {
        displayPreload(true);

        let tempLines =
          lines.length === 0 ? this.state.lines.map((l) => l.LineId) : lines;
        getUnassignedTasks(tempLines.join(","), routeFlag, teamFlag).then(
          (response) =>
            this.setState(
              {
                validationMessage: false,
                runTime: new Date(),
                data: response,
                selected: {
                  ...this.state.selected,
                  lines: tempLines,
                },
              },
              () => displayPreload(false)
            )
        );
      }
    });
  };

  handlerFilters = () => {
    this.setState({ showFilters: !this.state.showFilters });
  };

  handlerSelectBox = (values) => {
    this.setState({
      selected: { ...this.state.selected, lines: values },
    });
  };

  onChkValueChanged = (e) => {
    this.setState(
      {
        selected: {
          ...this.state.selected,
          [e.tag]: e.value,
        },
      },
      () => {
        let { routeFlag, teamFlag } = this.state.selected;
        document.getElementById("btnRunReport").disabled =
          !routeFlag && !teamFlag;
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
            <div className={styles.validationMessage}>
              <img src={icons.info} alt="" height="20px" />
              <label>
                Select the Production Line(s) for which you want to get the
                report. <br />
                If you do not select any line, the report will be generated for
                all lines. <br />
                You must select whether you want the unassigned tasks for
                Routes, Teams or both.
              </label>
            </div>
            <div>
              <SelectBox
                id="sboLinesUnassignedTasks"
                text="Production Lines"
                enableSelectAll={true}
                enableClear={true}
                className={styles.selectBoxPM}
                store={lines}
                isMultiple={true}
                value={this.state.selected.lines}
                onChange={(values) => this.handlerSelectBox(values)}
                labelKey="LineDesc"
                valueKey="LineId"
                isLoading={false}
              />
              <div className={styles.checkboxContainer}>
                <CheckBox
                  id="chkRoutesUnassignedTasks"
                  tag="routeFlag"
                  text="Routes"
                  value={this.state.selected.routeFlag}
                  onValueChanged={this.onChkValueChanged}
                />
                <CheckBox
                  id="chkTeamsUnassignedTasks"
                  tag="teamFlag"
                  text="Teams"
                  value={this.state.selected.teamFlag}
                  onValueChanged={this.onChkValueChanged}
                />
              </div>
            </div>
          </Card>

          <Card id="cdrUnassignedTasks" autoHeight flat>
            {validationMessage ? (
              <div className={styles.validationMessage}>
                <Icon name="warning" />
                <label id="lblUnassignedTaksWarning">
                  Select the Production Line(s) for which you want to get the
                  report. <br />
                  If you do not select any line, the report will be generated
                  for all lines. <br />
                  You must select whether you want the unassigned tasks for
                  Routes, Teams or both.
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

export default UnassignedTasks;
