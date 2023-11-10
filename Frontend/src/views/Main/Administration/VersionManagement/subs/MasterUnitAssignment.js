import React, { PureComponent } from "react";
import Card from "../../../../../components/Card";
import icons from "../../../../../resources/icons";
import DataGrid, { Column, Selection } from "devextreme-react/ui/data-grid";
import SelectBox from "../../../../../components/SelectBox";
import Button from "../../../../../components/Button";
import { gridMasterUnitAssignmentColumns } from "../options";
import { setIdsByClassName } from "../../../../../utils";
import { showMsg } from "../../../../../services/notification";
import styles from "../styles.module.scss";

export default class MasterUnitAssignment extends PureComponent {
  constructor(props) {
    super(props);
    this.refGrid = React.createRef();

    this.state = {
      rowsUpdated: [],
      selectedIsDone: false,
      selected: {
        unit: [],
      },
    };
  }

  componentDidUpdate = (prevProps, prevState) => {
    if (prevProps.opened !== this.props.opened) {
      if (!this.props.opened) {
        this.setState({ selectedIsDone: false });
      }
    }
    setTimeout(() => {
      setIdsByClassName([
        // Checkbox rows
        {
          idContainer: "grdPlantModelDS",
          class: "dx-checkbox-container",
          ids: ["chkGrdPlantModelDS"],
          same: true,
        },
        {
          idContainer: "sboMasterUnitAssignment",
          tagName: "input",
          ids: ["txtSearchsboMasterUnitAssignment"],
        },
      ]);
    }, 1000);
  };

  checkSelections = () => {
    let unit = this.state.selected.unit;
    let refGrid = this.refGrid.current.instance;
    let selectedRow = refGrid.getSelectedRowsData();
    let t = this.props.t;
    if (unit.length === 0 || selectedRow.length === 0) {
      showMsg(
        "warning",
        t("You must assign a Primary Unit to each module."),
        "",
        false
      );
      return false;
    } else {
      this.setState({ selectedIsDone: true });
      return { unit, selectedRow };
    }
  };

  onAssignSelected = () => {
    if (this.checkSelections() !== false) {
      let refGrid = this.refGrid.current.instance;
      let { unit, selectedRow } = this.checkSelections();
      selectedRow.map((x) => (x.MasterUnitDesc = unit[0]));
      refGrid.refresh();
    }
  };

  onAssignCompleted = () => {
    let t = this.props.t;
    let refGrid = this.refGrid.current.instance;
    let selectedRow = refGrid.getSelectedRowsData();
    if (selectedRow.length !== 0) {
      this.props.updateRowsMasterAssignment(selectedRow);
    } else showMsg("warning", t("Please, select at least one row."), "", false);
  };

  handlerUnit = (unit) => {
    this.setState({
      selected: {
        unit: unit,
      },
    });
  };

  render() {
    const { t, unitsForaLine, plantModelDS } = this.props;
    const { selected, selectedIsDone } = this.state;

    return (
      <React.Fragment>
        <Card id="crdMasterUnitAssignment" autoHeight>
          <div className={styles.masterAssignmentMessage}>
            <img alt="" src={icons.info} />
            <label>
              {t(
                "It was detected that the Raw Data file contains new modules."
              )}
              <br />
              <br />
              {t(
                "eCIL will automatically create those modules, but you need to specify for each one under which Primary Unit they should be created."
              )}
            </label>
          </div>
          <hr />
          <div className={styles.divAssignPopup}>
            <SelectBox
              id="sboMasterUnitAssignment"
              key={"MasterEquipment"}
              text={t("Primary Unit")}
              enableSelectAll={false}
              enableClear={true}
              store={unitsForaLine}
              value={selected.unit}
              onChange={(value) => this.handlerUnit(value)}
              isMultiple={false}
              labelKey="MasterDesc"
              valueKey="MasterDesc"
              className={styles.selectBoxMasteAssignmentPopup}
            />
            <Button
              id="btnMasterUnitAssignSelected"
              classes={styles.btnMasterUnitAssign}
              text="Assign Selected"
              onClick={() => this.onAssignSelected()}
            />
            <Button
              id="btnMasterUnitAssignCompleted"
              classes={styles.btnMasterUnitAssign}
              text="Assignment completed"
              disabled={!selectedIsDone}
              onClick={() => this.onAssignCompleted()}
            />
          </div>
          <hr />
          <DataGrid
            id="grdPlantModelDS"
            ref={this.refGrid}
            dataSource={plantModelDS}
            noDataText="No data"
            allowColumnReordering={true}
            allowFiltering={true}
            showBorders={false}
          >
            <Selection
              allowSelectAll={true}
              mode="multiple"
              showCheckBoxesMode="always"
            />
            {gridMasterUnitAssignmentColumns.map((col) => {
              if (col.dataField === "MasterUnitDesc")
                return (
                  <Column
                    key={col.dataField}
                    dataField={col.dataField}
                    caption={t(col.caption)}
                    alignment="left"
                    cellTemplate={(container, value) => {
                      container.style =
                        value.value === "" && "background-color: #ff0000";
                      let j = document.createElement("span");
                      j.appendChild(document.createTextNode(value.value));
                      container.appendChild(j);
                    }}
                  />
                );
              else
                return (
                  <Column
                    key={col.dataField}
                    dataField={col.dataField}
                    caption={t(col.caption)}
                    alignment="left"
                  />
                );
            })}
          </DataGrid>
          <br />
        </Card>
      </React.Fragment>
    );
  }
}
