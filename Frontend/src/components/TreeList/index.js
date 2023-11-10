import React, { PureComponent } from "react";
import { TreeList as DXTreeList } from "devextreme-react/ui/tree-list";

class TreeList extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  render() {
    const {
      id,
      reference,
      dataSource,
      columns,
      itemsExpr,
      keyExpr,
      parentIdExpr,
      rootValue,
      height,
      noDataText,
      wordWrapEnabled,
      showColumnHeaders,
      showColumnLines,
      loadPanelEnabled,
      defaultSelectedRowKeys,
      defaultExpandedRowKeys,
      onCellClick,
      onSelectionChanged,
      onRowExpanded,
      onRowExpanding,
    } = this.props;

    return (
      <DXTreeList
        id={id || undefined}
        ref={reference || null}
        dataSource={dataSource || null}
        columns={columns || undefined}
        itemsExpr={itemsExpr || "items"}
        keyExpr={keyExpr || "id"}
        parentIdExpr={parentIdExpr || "parentId"}
        rootValue={rootValue || "0"}
        height={height || "100%"}
        noDataText={noDataText || ""}
        loadPanel={{ enabled: loadPanelEnabled || false }}
        wordWrapEnabled={wordWrapEnabled || true}
        showColumnHeaders={showColumnHeaders || false}
        showColumnLines={showColumnLines || false}
        defaultSelectedRowKeys={defaultSelectedRowKeys || []}
        defaultExpandedRowKeys={defaultExpandedRowKeys || []}
        onCellClick={onCellClick || undefined}
        onSelectionChanged={onSelectionChanged || undefined}
        onRowExpanded={onRowExpanded || undefined}
        onRowExpanding={onRowExpanding || undefined}
      >
        {this.props.children}
      </DXTreeList>
    );
  }
}

export default TreeList;
