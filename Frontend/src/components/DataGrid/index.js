import React, { Component, memo } from "react";
import { translate } from "react-i18next";
import { DataGrid as DXDataGrid } from "devextreme-react/ui/data-grid";
import {
  Column,
  FilterRow,
  Export,
  Grouping,
  GroupPanel,
  SearchPanel,
  ColumnChooser,
  Scrolling,
  FilterPanel,
  RequiredRule,
} from "devextreme-react/ui/data-grid";
import { setIdsByClassName } from "../../utils";
import { entriesCompare } from "../../utils/index";

class DataGrid extends Component {
  constructor(props) {
    super(props);

    this.state = {};
  }

  shouldComponentUpdate = (nextProps, nextState) => {
    return (
      !entriesCompare(nextProps.dataSource, this.props.dataSource) ||
      nextProps.onToolbarPreparing !== this.props.onToolbarPreparing
    );
  };

  setComponentIds = () => {
    setTimeout(() => {
      setIdsByClassName([
        // Columns Header
        {
          idContainer: this.props.identity,
          class: "dx-texteditor-input",
          ids: ["txt" + this.props.identity],
          same: true,
        },
        {
          idContainer: this.props.identity,
          class: "dx-datagrid-drag-action",
          ids: ["btnColumnHeaderDragAction" + this.props.identity],
          same: true,
        },
        {
          idContainer: this.props.identity,
          class: "dx-column-indicators",
          ids: ["btnColumnHeaderFilterOptions" + this.props.identity],
          same: true,
        },
        {
          idContainer: this.props.identity,
          class: "dx-icon dx-icon-filter-operation-default",
          ids: ["btnColumnHeaderTypeOfSearch" + this.props.identity],
          same: true,
        },
        // Buttons: Save and cancel (On edit)
        {
          idContainer: this.props.identity,
          class: "dx-link dx-link-icon",
          ids: ["lnk" + this.props.identity],
          same: true,
        },
        // Checkboxs
        {
          idContainer: this.props.identity,
          class: "dx-checkbox-container",
          ids: ["chk" + this.props.identity],
          same: true,
        },
        // Edit button
        {
          idContainer: this.props.identity,
          class: " dx-link-edit",
          ids: ["btnEdit" + this.props.identity],
          same: true,
        },
      ]);
    }, 1000);
    setTimeout(() => {
      setIdsByClassName([
        {
          idContainer: this.props.identity,
          class: "dx-page",
          ids: ["btnPage" + this.props.identity],
          same: true,
        },
      ]);
    }, 3000);
  };

  render() {
    const {
      t,
      identity,
      reference,
      elementAttr,
      keyExpr,
      dataSource,
      allowColumnReordering,
      allowFiltering,
      allowColumnResizing = true,
      showColumnLines,
      showRowLines,
      columnResizingMode,
      rowAlternationEnabled,
      rtlEnabled,
      columnAutoWidth,
      columnHidingEnabled,
      headerFilter,
      loadPanel,
      noDataText,
      showBorders,
      wordWrapEnabled,
      height,
      width,
      onRowInserting,
      onRowUpdating,
      onRowPrepared,
      onCellPrepared,
      onCellClick,
      onSelectionChanged,
      onToolbarPreparing,
      onAdaptiveDetailRowPreparing,
      onEditingStart,
      onContentReady,
      onEditorPreparing,
      searchPanelVisible,
      columnChooserEnabled,
      exportEnabled,
      groupPanelVisible,
      defaultSelectedRowKeys,
      scrollingMode,
      rowDragging,
      customizeColumns,
      highlightChanges,
      filterRow,
      filterPanelEnabled,
      onOptionChanged,
      columns = [],
    } = this.props;

    return (
      <DXDataGrid
        id={identity || undefined}
        ref={reference || null}
        elementAttr={elementAttr || {}}
        keyExpr={keyExpr || null}
        dataSource={dataSource}
        allowColumnReordering={allowColumnReordering || true}
        allowFiltering={allowFiltering || true}
        allowColumnResizing={allowColumnResizing}
        showColumnLines={showColumnLines || true}
        showRowLines={showRowLines || true}
        showBorders={showBorders || true}
        highlightChanges={highlightChanges || false}
        wordWrapEnabled={wordWrapEnabled || false}
        columnResizingMode={columnResizingMode || "widget"}
        rowAlternationEnabled={rowAlternationEnabled || false}
        rtlEnabled={rtlEnabled || false}
        columnAutoWidth={columnAutoWidth || false}
        columnHidingEnabled={columnHidingEnabled || false}
        headerFilter={headerFilter || { visible: true }}
        loadPanel={loadPanel || { enabled: false }}
        noDataText={noDataText || ""}
        height={height || "100%"}
        width={width || "100%"}
        defaultSelectedRowKeys={defaultSelectedRowKeys || undefined}
        rowDragging={rowDragging || undefined}
        onRowInserting={onRowInserting || undefined}
        onRowUpdating={onRowUpdating || undefined}
        onRowPrepared={onRowPrepared || undefined}
        onCellPrepared={onCellPrepared || undefined}
        onCellClick={onCellClick || undefined}
        onSelectionChanged={onSelectionChanged || undefined}
        onToolbarPreparing={onToolbarPreparing || undefined}
        onAdaptiveDetailRowPreparing={onAdaptiveDetailRowPreparing || undefined}
        onEditingStart={onEditingStart || undefined}
        onEditorPreparing={onEditorPreparing || undefined}
        onContentReady={onContentReady || undefined}
        onDisposing={this.setComponentIds()}
        customizeColumns={customizeColumns || undefined}
        onOptionChanged={onOptionChanged || undefined}
      >
        <Scrolling
          mode={scrollingMode || "virtual"}
          preloadEnabled={true}
          showScrollbar="onHover"
        />
        <SearchPanel visible={searchPanelVisible ?? false} />
        <ColumnChooser enabled={columnChooserEnabled ?? false} />
        <Export enabled={exportEnabled ?? false} />
        <GroupPanel visible={groupPanelVisible ?? false} />
        <Grouping autoExpandAll={true} contextMenuEnabled={false} />
        <FilterRow
          visible={filterRow !== false ? true : false}
          applyFilter="auto"
        />
        <FilterPanel filterEnabled={filterPanelEnabled || true} />
        {this.props.children}
        {columns.map((column) => {
          const {
            caption,
            dataField,
            visibility,
            alignment,
            allowExporting,
            allowEditing,
            allowFiltering,
            allowSearch,
            width,
            cellTemplate,
            editCellRender,
            visibleIndex,
            showInColumnChooser,
            sortOrder,
            customizeText,
            hidingPriority,
            showEditorAlways,
            validationRules,
            groupIndex,
            cellRender,
            dataType,
            headerFilter,
            defaultSortOrder,
            allowSorting = true,
          } = column;

          return (
            <Column
              key={caption ?? Math.floor(Math.random() * 900) + 100}
              caption={t(caption)}
              dataField={dataField}
              width={width}
              visible={visibility ?? true}
              allowEditing={allowEditing ?? false}
              allowFiltering={allowFiltering ?? true}
              allowSearch={allowSearch ?? true}
              showInColumnChooser={showInColumnChooser ?? true}
              allowExporting={allowExporting ?? true}
              alignment={alignment || "left"}
              cellTemplate={cellTemplate || undefined}
              editCellRender={editCellRender || undefined}
              visibleIndex={visibleIndex || undefined}
              sortOrder={sortOrder || undefined}
              customizeText={customizeText || undefined}
              hidingPriority={hidingPriority || undefined}
              showEditorAlways={showEditorAlways ?? undefined}
              groupIndex={groupIndex || undefined}
              cellRender={cellRender || undefined}
              dataType={dataType || undefined}
              headerFilter={headerFilter || undefined}
              defaultSortOrder={defaultSortOrder || undefined}
              allowSorting={allowSorting}
            >
              {validationRules !== undefined && <RequiredRule />}
            </Column>
          );
        })}
      </DXDataGrid>
    );
  }
}

export default translate()(memo(DataGrid));
