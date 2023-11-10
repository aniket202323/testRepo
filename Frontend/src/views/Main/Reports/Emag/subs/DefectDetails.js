import React, { PureComponent } from "react";
import DataGrid from "../../../../../components/DataGrid";
import { Column } from "devextreme-react/ui/data-grid";

class DefectDetails extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  render() {
    const { t, data } = this.props;

    return (
      <DataGrid
        identity="grdDefectDetails"
        dataSource={data || []}
        elementAttr={{ style: "zoom: 80%;" }}
        showBorders={false}
        rowAlternationEnabled={false}
        allowColumnReordering={false}
        allowColumnResizing={false}
        columnAutoWidth={true}
        columnResizingMode={"nextColumn"}
        searchPanelVisible={false}
        filterRow={false}
      >
        <Column
          caption={t("Created On")}
          dataField="DefectStart"
          allowFiltering={false}
        />
        <Column
          caption={t("Closed On")}
          dataField="DefectEnd"
          allowFiltering={false}
        />
        <Column caption={t("FL")} dataField="FL" allowFiltering={false} />
        <Column
          caption={t("Type")}
          dataField="DefectType"
          allowFiltering={false}
        />
        <Column
          caption={t("Reported By")}
          dataField="ReportedBy"
          allowFiltering={false}
        />
        <Column
          caption={t("Notification #")}
          dataField="Notification"
          allowFiltering={false}
        />
        <Column
          caption={t("Description")}
          dataField="Description"
          allowFiltering={false}
        />
      </DataGrid>
    );
  }
}

export default DefectDetails;
