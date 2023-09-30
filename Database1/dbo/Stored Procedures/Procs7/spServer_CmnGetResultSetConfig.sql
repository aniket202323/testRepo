CREATE PROCEDURE dbo.spServer_CmnGetResultSetConfig
AS
Select a.RSTId,b.RstDesc,b.Message_Id,a.ColumnNum,a.UsedAsPropertyName,a.ActualPropertyName,d.MsgPropertyDesc,a.MsgPropertyId,a.DefaultValue,b.PreColumnNum,b.PreRouteId,b.PostColumnNum,b.PostRouteId,b.KeyColumnNum,d.MsgPropertyDataType
 	 From ResultSetConfig a
 	 Join ResultSetTypes b on (b.RSTId = a.RSTId)
 	 Join Message_Types c on (c.Message_Id = b.Message_Id)
 	 Left Outer Join Message_Properties d on (d.MsgPropertyId = a.MsgPropertyId)
 	 Order By a.RSTId,a.ColumnNum
