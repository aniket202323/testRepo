CREATE PROCEDURE dbo.spServer_PMgrSaveStatisticByKey
@Id int,
@Value nVarChar(50),
@ModifiedOn datetime
AS 
insert into Performance_Statistics (Key_Id, Value, Modified_On) values (@id, @Value, @ModifiedOn)
