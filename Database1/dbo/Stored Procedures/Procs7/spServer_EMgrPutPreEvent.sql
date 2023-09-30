CREATE PROCEDURE dbo.spServer_EMgrPutPreEvent
@PU_Id int,
@Event_Num nVarChar(50),
@TimeStamp datetime
 AS
Insert Into PreEvents (PU_Id,Event_Num,TimeStamp) Values (@PU_Id,@Event_Num,@TimeStamp)
