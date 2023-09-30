CREATE Procedure dbo.spS88H_GetSettings
@HistorianName nvarchar(100)
AS
Create Table #Settings (
  Name nvarchar(100),
  Value nvarchar(100)
)
Insert Into #Settings (Name, Value) Values ('Debug', '1')
Insert Into #Settings (Name, Value) Values ('ScanInterval', '30')
Insert Into #Settings (Name, Value) Values ('ScanWindow', '2')
Insert Into #Settings (Name, Value) Values ('ModelNumber', '118')
Insert Into #Settings (Name, Value) Values ('PurgeCount', '1000')
Insert Into #Settings (Name, Value) Values ('PurgeDays', '10')
Insert Into #Settings (Name, Value) Values ('Separator', '_')
Insert Into #Settings (Name, Value) Values ('MovementKey', 'MaterialBatchId')
Insert Into #Settings (Name, Value) Values ('FieldKey', 'Field')
Insert Into #Settings (Name, Value) Values ('ValueKey', 'Value')
Insert Into #Settings (Name, Value) Values ('QualityTagKey', 'BDQ')
Insert Into #Settings (Name, Value) Values ('MaxMessages', '30')
Select * From #Settings
Drop Table #Settings
