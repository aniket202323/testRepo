CREATE PROCEDURE dbo.spServer_OPCGetResultSetMap
AS
select OPC_Type_Id        as Type,
       Prop_Id            as Property,
       Value_Row          as ValueRow,
       Value_Col          as ValueCol,
       Time_Row           as TimeRow,
       Time_Col           as TimeCol
  from OPC_ResultSet_Map
