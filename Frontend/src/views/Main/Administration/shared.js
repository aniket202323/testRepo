import { getTasksPlantModelEditList } from "../../../services/tasks";

//#region Routes and Teams Management

const groupBy = (items, key) =>
  items.reduce(
    (result, item) => ({
      ...result,
      [item[key]]: [...(result[item[key]] || []), item],
    }),
    {}
  );

function buildTreeListLines(state) {
  return new Promise((resolve) => {
    let tempTreeListData = state.treeListData;
    let linesDS = state.linesDS;
    let tasksDS = [...state.tasksDS];
    let linesLoaded = [...state.linesLoaded];

    let item = {};
    let lastId = tempTreeListData.length + 1;

    if (tasksDS.length > 0) {
      linesDS = linesDS.filter(
        (x) => !linesLoaded.some((y) => y === x.LineDesc)
      );
    }

    linesDS.forEach((line, index) => {
      item = {
        Id: lastId,
        ParentId: 0,
        Level: 1,
        ItemId: line.LineId,
        ItemDesc: line.LineDesc,
        TaskOrder: 0,
        Selected: false,
        LineId: line.LineId,
      };

      tempTreeListData.push(item);
      let tempId = lastId;
      lastId++;

      item = {
        Id: line.LineId * 1000000000,
        ParentId: tempId,
        Level: 2,
        ItemId: line.LineId,
        ItemDesc: "...",
        TaskOrder: 0,
        Selected: false,
        LineId: line.LineId,
      };

      tempTreeListData.push(item);
      lastId += 99999999;
      if (linesDS.length === index + 1) resolve(tempTreeListData);
    });
  });
}

function buildTreeListItems(line, state, checkAll) {
  let newTreeListData = state.treeListData;
  let lineId = line[0] === undefined ? line.LineId : line[0];
  let LineDesc = state.linesDS.find((x) => x.LineId === lineId)?.LineDesc;
  let tasks = [];
  let item = {};
  let lastParentId = newTreeListData.length !== 0 ? newTreeListData.length : 0;

  let lastId = newTreeListData.find((x) => x.ItemDesc === LineDesc)?.Id + 1;
  lastParentId = lastId;
  lastParentId--;

  return new Promise((resolve) =>
    resolve(
      getTasksPlantModelEditList("", lineId).then((response) => {
        tasks = response;
        let masterEquipment = Object.keys(groupBy(tasks, "MasterUnitDesc"));
        for (let i_1 = 0; i_1 < masterEquipment.length; i_1++) {
          item = {
            Id: lastId,
            ParentId: lastParentId,
            Level: 2,
            ItemId: tasks.find((x) => x.MasterUnitDesc === masterEquipment[i_1])
              ?.PLId,
            ItemDesc: masterEquipment[i_1],
            TaskOrder: 0,
            Selected: checkAll,
            LineId: lineId,
          };

          newTreeListData.push(item);
          lastId++;
          let tempLastIdSalve = lastId;
          tempLastIdSalve--;

          let modulesByMaster = Object.keys(
            groupBy(
              tasks.filter(
                (item) => item.MasterUnitDesc === masterEquipment[i_1]
              ),
              "SlaveUnitDesc"
            )
          );

          for (let i_2 = 0; i_2 < modulesByMaster.length; i_2++) {
            item = {
              Id: lastId,
              ParentId: tempLastIdSalve,
              Level: 3,
              ItemId: tasks.find(
                (x) => x.SlaveUnitDesc === modulesByMaster[i_2]
              )?.SlaveUnitId,
              ItemDesc: modulesByMaster[i_2],
              TaskOrder: 0,
              Selected: checkAll,
              LineId: lineId,
            };

            newTreeListData.push(item);
            lastId++;
            let tempLastIdGroup = lastId;
            tempLastIdGroup--;

            let groupsBySlave = Object.keys(
              groupBy(
                tasks.filter(
                  (item) => item.SlaveUnitDesc === modulesByMaster[i_2]
                ),
                "ProductionGroupDesc" // "FL4"
              )
            );

            for (let i_3 = 0; i_3 < groupsBySlave.length; i_3++) {
              item = {
                Id: lastId,
                ParentId: tempLastIdGroup,
                Level: 4,
                ItemId: lastId,
                ItemDesc: groupsBySlave[i_3].includes("CIL")
                  ? "eCIL"
                  : groupsBySlave[i_3],
                TaskOrder: 0,
                Selected: checkAll,
                LineId: lineId,
              };

              newTreeListData.push(item);
              lastId++;
              let tempLastIdTask = lastId;
              tempLastIdTask--;

              let tasksByMasterAndSlave = Object.keys(
                groupBy(
                  tasks.filter(
                    (item) =>
                      item.MasterUnitDesc === masterEquipment[i_1] &&
                      item.SlaveUnitDesc === modulesByMaster[i_2] &&
                      item.ProductionGroupDesc === groupsBySlave[i_3] // "FL4"
                  ),
                  "VarDesc"
                )
              );

              for (let i_4 = 0; i_4 < tasksByMasterAndSlave.length; i_4++) {
                let itemId = tasks.find(
                  (x) =>
                    x.MasterUnitDesc === masterEquipment[i_1] &&
                    x.SlaveUnitDesc === modulesByMaster[i_2] &&
                    x.VarDesc === tasksByMasterAndSlave[i_4]
                )?.VarId;

                item = {
                  Id: lastId,
                  ParentId: tempLastIdTask,
                  Level: 5,
                  ItemId: itemId,
                  ItemDesc: tasksByMasterAndSlave[i_4],
                  TaskOrder: 0,
                  Selected: checkAll,
                  Line: LineDesc,
                  MasterUnit: masterEquipment[i_1],
                  SlaveUnit: modulesByMaster[i_2],
                  Group: groupsBySlave[i_3].includes("CIL")
                    ? "eCIL"
                    : groupsBySlave[i_3],
                  LineId: lineId,
                };

                newTreeListData.push(item);
                lastId++;
              }
            }
          }
        }
        lastParentId++;
        for (var i = 0; i < newTreeListData.length; i++)
          if (newTreeListData[i].Id === line.LineId * 1000000000) {
            newTreeListData.splice(i, 1);
            break;
          }

        let tempLinesLoaded = state.linesLoaded;
        tempLinesLoaded.push(LineDesc);
        return { tempLinesLoaded, newTreeListData };
      })
    )
  );
}

function treeListTasksSelected(currentLevel, currentIds, treeListData) {
  var treeDS = JSON.parse(JSON.stringify(treeListData));
  var tempIds = currentIds;
  currentLevel += 1;

  for (var i = currentLevel; i <= 5; i++) {
    // eslint-disable-next-line no-loop-func
    tempIds = treeDS.filter((elem) =>
      tempIds.some((current) => current.Id === elem.ParentId)
    );
  }

  return tempIds;
}

function treeListExpandedKeys(data, rowsIds) {
  if (rowsIds.length > 0) {
    var ds = JSON.parse(JSON.stringify(data));
    var ids = JSON.parse(JSON.stringify(rowsIds));
    var temp = ids;
    var result = ids;

    for (var i = 5; i > 1; i--) {
      temp = ds
        .filter((d) => ids.some((id) => id === d.Id))
        .map((m) => m.ParentId);
      result.push(...temp);
    }
    return [...new Set(result)].sort((a, b) => a - b);
  } else return [];
}

function uniqueItemId(array) {
  return array.filter(
    (element, index, self) =>
      index === self.findIndex((t) => t.ItemId === element.ItemId)
  );
}

//#endregion

export {
  buildTreeListLines,
  buildTreeListItems,
  treeListTasksSelected,
  treeListExpandedKeys,
  uniqueItemId,
};
