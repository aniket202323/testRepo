import React, { Component } from "react";
import {
  FilterRow,
  Pager,
  Paging,
  Export,
  Grouping,
  GroupPanel,
  SearchPanel,
  FilterPanel,
  Scrolling,
} from "devextreme-react/ui/data-grid";
import {
  generateExportDocument,
  setIdsByClassName,
} from "../../../../../utils/index";
import { warning } from "../../../../../services/notification";
import {
  gridSchedulingErrorsToolbarPreparing,
  gridSchedulingErrorsColumns,
} from "../options";
import DataGrid from "../../../../../components/DataGrid";
import DataSource from "devextreme/data/data_source";
import { isTablet } from "../../../../../utils";
import styles from "../styles.module.scss";

class Grid extends Component {
  constructor(props) {
    super(props);
    this.refGrid = React.createRef();
  }

  componentDidUpdate = () => {
    setIdsByClassName([
      "btnExcelExportSchedulingErrors",
      "btnPdfExportSchedulingErrors",
    ]);
  };

  setIdsGridComponents = () => {
    setIdsByClassName([
      {
        idContainer: "grdSchedulingErrors",
        class: "dx-texteditor-input",
        ids: ["txtColumnSearchGrdSchedulingErrors"],
        same: true,
      },
    ]);
  };

  async generateExportData() {
    let refGrid = this.refGrid.current.instance;

    let columns = Array(
      refGrid.getVisibleColumns().reduce(
        (obj, item) => (
          // eslint-disable-next-line no-sequences
          (obj[item.dataField] = this.props.t(item.caption)), obj
        ),
        {}
      )
    );

    let data = await new DataSource({
      store: [...refGrid.getDataSource().store()._array],
      filter: refGrid.getCombinedFilter(),
      sort: refGrid.getDataSource().sort(),
      paginate: false,
    }).load();

    return { columns, data };
  }

  onClickExportToPDF = async () => {
    var fontReady = document
      .getElementById("root")
      .getAttribute("data-pdf-font-ready");

    if (fontReady === "false" && localStorage.i18nextLng === "zh") {
      warning(
        "The font to export to pdf is not already loaded, please wait a seconds and try again"
      );
    } else {
      const { columns, data } = await this.generateExportData();
      var pdfdoc = generateExportDocument(columns, data);
      pdfdoc.save("gvTasks.pdf");
    }
  };

  onClickExportToExcel = () => {
    let grid = this.refGrid.current.instance;
    grid.exportToExcel(false);
  };

  render() {
    const { t, runTime, data } = this.props;

    if (runTime === null) return null;
    return (
      <React.Fragment>
        <div className={styles.dataGridContainer}>
          <DataGrid
            identity="grdSchedulingErrors"
            reference={this.refGrid}
            dataSource={{
              store: data,
            }}
            allowColumnReordering={false}
            allowColumnResizing={false}
            columnAutoWidth={true}
            columnResizingMode={"nextColumn"}
            scrollingMode="standard"
            onContentReady={this.setIdsGridComponents}
            onToolbarPreparing={(e) =>
              gridSchedulingErrorsToolbarPreparing(
                e,
                t,
                this.onClickExportToExcel,
                this.onClickExportToPDF
              )
            }
            columns={gridSchedulingErrorsColumns()}
          >
            <SearchPanel visible={false} />
            <Export enabled={false} fileName="gvTasks" />
            <GroupPanel visible={true} />
            <Grouping autoExpandAll={true} contextMenuEnabled={false} />
            <FilterRow visible={true} applyFilter="auto" />
            <FilterPanel filterEnabled={true} />
            <Paging enabled={true} pageSize={40} />
            <Pager
              showPageSizeSelector={false}
              showNavigationButtons={false}
              showInfo={true}
              visible={isTablet() ? false : true}
            />
            <Scrolling mode={isTablet() ? "virtual" : "standard"} />
          </DataGrid>
        </div>
      </React.Fragment>
    );
  }
}

export default Grid;
