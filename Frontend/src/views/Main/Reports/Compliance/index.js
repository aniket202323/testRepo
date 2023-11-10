import React, { PureComponent } from "react";
import Filters from "./subs/Filters";
import Card from "../../../../components/Card";
import Button from "../../../../components/Button";
import ColorCoding from "../../../../components/ColorCoding";
import Content from "./subs/Content";
import PrintContent from "./subs/Print/Content";
import { setBreadcrumbEvents } from "../../../../components/Framework/Breadcrumb/events";
import styles from "./styles.module.scss";

class Compliance extends PureComponent {
  constructor(props) {
    super(props);

    this.refFilters = React.createRef();

    this.state = {
      showFilters: true,
      showPrint: false,
      runTime: null,
    };
  }

  componentDidMount = () => {
    const { t } = this.props;
    setBreadcrumbEvents(
      <nav>
        <Button
          id="btnShowHideFilters"
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
        <Button
          id="btnRunPrint"
          icon="print"
          hint={t("Print Report")}
          primary
          disabled={false}
          classes={styles.breadcrumbButton}
          onClick={this.handlerPrint}
        />
      </nav>
    );
  };

  handlerFilters = () => {
    this.setState({ showFilters: !this.state.showFilters });
  };

  handlerReport = () => {
    if (this.state.showFilters) this.handlerFilters();
    this.setState({ runTime: new Date(), showPrint: false });
  };

  handlerPrint = () => {
    if (this.state.showFilters) this.handlerFilters();
    this.setState({ runTime: new Date(), showPrint: true });
  };

  render() {
    const { t } = this.props;
    const { showFilters, runTime, showPrint } = this.state;

    return (
      <React.Fragment>
        <div className={styles.container}>
          <Card
            id="crdComplianceFilters"
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

          {!showPrint && (
            <Card id="crdComplianceContent" autoHeight flat>
              {runTime !== null && (
                <Content t={t} runTime={runTime} refFilters={this.refFilters} />
              )}
            </Card>
          )}

          {showPrint && (
            <Card id="crdCompliancePrint" autoHeight flat>
              {runTime !== null && (
                <PrintContent
                  t={t}
                  runTime={runTime}
                  refFilters={this.refFilters}
                />
              )}
            </Card>
          )}

          <ColorCoding
            t={t}
            report="compliance"
            visible={runTime !== null && !showPrint}
            classes={styles.colorCoding}
          />
        </div>
      </React.Fragment>
    );
  }
}

export default Compliance;
