CREATE PROCEDURE dbo.spServer_EMgrCleanupWaste
@Event_Id int,
@Type_Id int
 AS
Select WED_Id = WED_Id,
       PU_Id = PU_Id,
       WYear = DatePart(Year,TimeStamp),
       WMonth = DatePart(Month,TimeStamp),
       WDay = DatePart(Day,TimeStamp),
       WHour = DatePart(Hour,TimeStamp),
       WMin = DatePart(Minute,TimeStamp),
       WSec = DatePart(Second,TimeStamp)
  From Waste_Event_Details
  Where (Event_Id = @Event_Id) And
        (WET_Id = @Type_Id)
