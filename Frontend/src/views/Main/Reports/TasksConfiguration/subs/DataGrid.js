import React, { Component } from "react";
import Button from "../../../../../components/Button";
import Input from "../../../../../components/Input";
import RadioGroup from "../../../../../components/RadioGroup";
import DataGrid from "../../../../../components/DataGrid";
import {
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
import { confirm, warning } from "devextreme/ui/dialog";
import { Popup } from "devextreme-react/ui/popup";
import {
  generateExportDocument,
  entriesCompare,
  setIdsByClassName,
  getIcon,
} from "../../../../../utils/index";
import {
  getCustomView,
  saveCustomView,
  deleteCustomView,
} from "../../../../../services/customView";
import { getUserId } from "../../../../../services/auth";
import {
  gridTasksToolbarPreparing,
  gridTasksColumns,
  filterGrid,
} from "../options";
import icons from "../../../../../resources/icons";
import DataSource from "devextreme/data/data_source";
import { isTablet } from "../../../../../utils";

class Grid extends Component {
  constructor(props) {
    super(props);
    this.refGrid = React.createRef();

    this.state = {
      customsViews: [],
      customViewActive: "Plant Model View",
      customViewDialogOpened: false,
      customViewRdgOption: "NewView",
    };
  }

  componentDidMount = () => {
    getCustomView("TasksConfigurationReport").then((response) => {
      this.setState({ customsViews: response });
    });
  };

  shouldComponentUpdate(nextProps, nextState) {
    if (
      nextProps.runTime !== this.props.runTime ||
      !entriesCompare(nextState, this.state)
    )
      return true;
    else return false;
  }

  componentDidUpdate = () => {
    setIdsByClassName([
      "btnCustomizeGridTasksConfiguration",
      {
        idContainer: "grdTasksConfiguration",
        class: "dx-datagrid-column-chooser-button",
        ids: ["btnColumnChooserTasksConfiguration"],
      },
      "btnExcelExportTasksConfiguration",
      "btnPdfExportTasksConfiguration",
    ]);
  };

  setIdsGridComponents = () => {
    setIdsByClassName([
      {
        idContainer: "grdTasksConfiguration",
        class: "dx-texteditor-input",
        ids: ["txtColumnSearchGrdTasksConfiguration"],
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
      let pdfdoc = generateExportDocument(columns, data);
      pdfdoc.save("gvTasks.pdf");
    }
  };

  onClickExportToExcel = () => {
    let grid = this.refGrid.current.instance;
    grid.exportToExcel(false);
  };

  //#region customs views

  onClickCustomizeView = (e) => {
    const { t } = this.props;
    const { customsViews, customViewActive } = this.state;

    let customViewDetail = customsViews.find(
      (cv) => cv.ViewDescription === customViewActive
    );

    if (e.item.id === -1) {
      //save custom view
      this.setState(
        {
          customViewDialogOpened: true,
          customViewRdgOption:
            customViewDetail.ViewType !== 99 ? "NewView" : "CurrentView",
        },
        () =>
          setTimeout(() => {
            document.querySelector("[name=customViewName]").value =
              this.state.customViewRdgOption !== "NewView"
                ? customViewDetail.ViewDescription
                : "";
          }, 400)
      );
    } else if (e.item.id === -2) {
      //delete custom view
      let dialog = confirm(
        `<span>Are you sure you want to delete this view: ${customViewDetail.ViewDescription}?</span>`,
        t("Delete Custom View")
      );
      dialog.then((dialogResult) => {
        if (dialogResult) {
          deleteCustomView(customViewDetail.UPId).then(() =>
            getCustomView("TasksConfigurationReport").then((response) =>
              this.setState({
                customsViews: response,
                customViewActive: "Plant Model View",
              })
            )
          );
        }
      });
    } else {
      let customView = customsViews.find((cv) => cv.UPId === e.item.id);
      this.refGrid.current.instance.state(JSON.parse(customView.Data));
      this.setState({ customViewActive: customView.ViewDescription });
    }
  };

  onClickSaveCustomView = () => {
    const { customsViews, customViewActive, customViewRdgOption } = this.state;

    var customViewDetail = customsViews.find(
      (cv) => cv.ViewDescription === customViewActive
    );

    let viewClass = {
      UPId: customViewRdgOption === "NewView" ? 0 : customViewDetail?.UPId,
      ViewType: 99,
      UserId: getUserId(),
      ViewDescription: document.querySelector("[name=customViewName]").value,
      Data: JSON.stringify(this.refGrid.current.instance.state()),
      ScreenDescription: "TasksConfigurationReport",
      ScreenId: 2,
      DefaultViewId: 7,
      IsPublic: true,
      IsDefault: 0,
      IsUserDefault: false,
      IsSiteDefault: false,
      MenuItemIndex: 0,
      IsWrapEnable: false,
    };

    saveCustomView(viewClass).then(() =>
      getCustomView("TasksConfigurationReport").then((response) =>
        this.setState({ customsViews: response, customViewDialogOpened: false })
      )
    );
  };

  onClickCloseCustomViewDialog = () => {
    this.setState({ customViewDialogOpened: false });
  };

  onRdgCustomViewChange = (e) => {
    const { customsViews, customViewActive } = this.state;

    var customViewDetail = customsViews.find(
      (cv) => cv.ViewDescription === customViewActive
    );

    this.setState({ customViewRdgOption: e.value });
    document.querySelector("[name=customViewName]").value =
      e.value !== "NewView" ? customViewDetail.ViewDescription : "";
  };

  customizeViewListItems = () => {
    const { t } = this.props;
    const { customsViews, customViewActive } = this.state;

    let customViewDetail =
      customsViews?.find((cv) => cv.ViewDescription === customViewActive) ?? [];
    let views = customsViews || [];

    return [
      {
        id: -1,
        text: t("Save Custom View"),
        icon: getIcon(icons.save),
      },
      {
        id: -2,
        text: t("Delete Custom View"),
        icon: getIcon(icons.remove),
        disabled: customViewDetail?.ViewType !== 99,
      },
      { html: "<hr/>", disabled: true },
      ...views
        .filter((cv) => cv.ViewType !== 99)
        .map((cv) => {
          return {
            id: cv.UPId,
            text: cv.ViewDescription,
            icon: cv.ViewDescription === customViewActive ? "check" : "empty",
          };
        }),
      {
        html: "<hr/>",
        disabled: true,
        visible: views.filter((cv) => cv.ViewType === 99).length > 0,
      },
      ...views
        .filter((cv) => cv.ViewType === 99)
        .map((cv) => {
          return {
            id: cv.UPId,
            text: cv.ViewDescription,
            icon: cv.ViewDescription === customViewActive ? "check" : "empty",
          };
        }),
    ];
  };

  //#endregion

  render() {
    const { t, runTime, data } = this.props;
    const {
      customsViews,
      customViewActive,
      customViewDialogOpened,
      customViewRdgOption,
    } = this.state;

    var customViewDetail = customsViews?.find(
      (cv) => cv?.ViewDescription === customViewActive
    );

    if (runTime === null) return null;
    return (
      <React.Fragment>
        <DataGrid
          identity="grdTasksConfiguration"
          reference={this.refGrid}
          dataSource={{
            store: data,
            filter: filterGrid(this.props.refFilters),
            // key: "VarId",
            // reshapeOnPush: false,
          }}
          allowColumnReordering={false}
          allowColumnResizing={false}
          columnAutoWidth={true}
          columnResizingMode={"nextColumn"}
          scrollingMode="standard"
          onContentReady={this.setIdsGridComponents}
          onToolbarPreparing={(e) =>
            gridTasksToolbarPreparing(
              e,
              t,
              this.onClickCustomizeView,
              this.onClickExportToExcel,
              this.onClickExportToPDF,
              this.customizeViewListItems
            )
          }
          columns={gridTasksColumns()}
        >
          <SearchPanel visible={false} />
          <ColumnChooser
            enabled={true}
            mode={isTablet() ? "select" : "dragAndDrop"}
          />
          <Export enabled={false} fileName="gvTasks" />
          <GroupPanel visible={true} />
          <Grouping autoExpandAll={true} contextMenuEnabled={false} />
          <FilterRow visible={true} applyFilter="auto" />
          <FilterPanel filterEnabled={true} />
          <Paging enabled={true} pageSize={20} />
          <Pager
            showPageSizeSelector={false}
            showNavigationButtons={false}
            showInfo={true}
            visible={isTablet() ? false : true}
          />
          <Scrolling mode={isTablet() ? "virtual" : "standard"} />
        </DataGrid>

        <Popup
          id="popCustomDialogView"
          visible={customViewDialogOpened}
          onHiding={this.onClickCloseCustomViewDialog}
          dragEnabled={false}
          closeOnOutsideClick={true}
          showTitle={true}
          title={t("Save Custom View")}
          showCloseButton={false}
          width="350px"
          height="175px"
        >
          <RadioGroup
            ref={this.refRdgCustomView}
            value={customViewRdgOption}
            valueExpr="value"
            onValueChanged={this.onRdgCustomViewChange}
            items={[
              {
                text: "Save Current View",
                value: "CurrentView",
                disabled: customViewDetail?.ViewType !== 99,
              },
              {
                text: "Save New View",
                value: "NewView",
                disabled: false,
                visible: true,
              },
            ]}
          />
          <Input
            id="txtCustomViewName"
            type="text"
            name="customViewName"
            onChange={(e) => e}
            border
            defaultValue=""
          />
          <Button text="Save" onClick={this.onClickSaveCustomView} />
          <Button text="Close" onClick={this.onClickCloseCustomViewDialog} />
        </Popup>
      </React.Fragment>
    );
  }
}

export default Grid;
