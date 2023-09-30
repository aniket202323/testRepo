Create Procedure dbo.spWD_GetSiteParms
AS
select p.Parm_Name, s.Value
   From parameters p
   Join Site_parameters s on s.Parm_Id = p.Parm_Id
   Where Parm_Name in ('GridComboBoxMaxDrop', 'DaysBackOpenDowntimeEventCanBeAdded', 'OpenDowntimeEventCanBeAddedDaysBack')
