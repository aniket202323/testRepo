import React, { Component } from "react";
import {
  Column,
  FilterRow,
  Pager,
  Paging,
  Export,
  Grouping,
  GroupPanel,
  SearchPanel,
  ColumnChooser,
  FilterPanel,
  Scrolling,
} from "devextreme-react/ui/data-grid";
import {
  generateExportDocument,
  getIcon,
  setIdsByClassName,
} from "../../../../../utils/index";
import { warning } from "../../../../../services/notification";
import DataGrid from "../../../../../components/DataGrid";
import icons from "../../../../../resources/icons";
import DataSource from "devextreme/data/data_source";
import { isTablet } from "../../../../../utils";

class Grid extends Component {
  constructor(props) {
    super(props);
    this.refGrid = React.createRef();

    this.state = {};
  }

  shouldComponentUpdate(nextProps, nextState) {
    if (nextProps.runTime !== this.props.runTime) return true;
    else return false;
  }

  componentDidUpdate = () => {
    setIdsByClassName([
      "btnExcelExportUnassignedTasks",
      "btnPdfExportUnassignedTasks",
    ]);
  };

  setIdsGridComponents = () => {
    setIdsByClassName([
      {
        idContainer: "grdUnassignedTasks",
        class: "dx-texteditor-input",
        ids: ["txtColumnSearchGrdUnassignedTasks"],
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
      pdfdoc.save("gvView.pdf");
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
      <DataGrid
        identity="grdUnassignedTasks"
        reference={this.refGrid}
        dataSource={data}
        showBorders={false}
        allowColumnReordering={false}
        allowColumnResizing={false}
        columnAutoWidth={true}
        columnResizingMode={"nextColumn"}
        scrollingMode="standard"
        onContentReady={this.setIdsGridComponents}
        onToolbarPreparing={(e) =>
          e.toolbarOptions.items.unshift(
            {
              location: "after",
              widget: "dxButton",
              cssClass: "btnExcelExportUnassignedTasks",
              options: {
                hint: t("Export to Excel"),
                icon: getIcon(icons.excel),
                onClick: this.onClickExportToExcel,
              },
            },
            {
              location: "after",
              widget: "dxButton",
              cssClass: "btnPdfExportUnassignedTasks",
              options: {
                hint: t("Export to PDF"),
                icon: getIcon(icons.pdf),
                onClick: this.onClickExportToPDF,
              },
            }
          )
        }
      >
        <SearchPanel visible={false} />
        <ColumnChooser enabled={false} />
        <Export enabled={false} fileName="gvView" />
        <GroupPanel visible={true} />
        <Grouping autoExpandAll={true} contextMenuEnabled={false} />
        <FilterRow visible={true} applyFilter="auto" />
        <FilterPanel filterEnabled={true} />
        <Paging enabled={true} pageSize={100} />
        <Pager
          showPageSizeSelector={false}
          showNavigationButtons={false}
          showInfo={true}
          visible={isTablet() ? false : true}
        />
        <Scrolling mode={isTablet() ? "virtual" : "standard"} />
        <Column caption={t("Line")} dataField="Line" />
        <Column caption={t("Primary Unit")} dataField="MasterUnit" />
        <Column caption={t("Module")} dataField="SlaveUnit" />
        <Column caption={t("Group")} dataField="Group" />
        <Column caption={t("Task")} dataField="Task" />
        {/* The next column is added to prevent errors when export to Excel with all the column grouped (anyway looks like DevExtreme datagrid has a limit of columns grouped) */}
        <Column visible={true} width={1} />
      </DataGrid>
    );
  }
}

export default Grid;
