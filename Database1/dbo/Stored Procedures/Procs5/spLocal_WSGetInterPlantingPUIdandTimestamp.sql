  
  
CREATE   PROCEDURE  dbo.spLocal_WSGetInterPlantingPUIdandTimestamp  
 @ULID  VARCHAR(25)  
   
AS  
DECLARE @PUId  INT ,  
 @Timestamp DATETIME ,  
 @Event_Id INT   
BEGIN  
  
SET @PUId = NULL  
SELECT @PUId = PU_Id,  
 @Timestamp = Timestamp,  
 @Event_Id = Event_Id  
 FROM Events e  
 JOIN Production_Status ps ON ps.ProdStatus_Id = e.Event_Status  
 WHERE Event_Num = @ULID  
-- AND ps.Count_For_Inventory = 1  
  
SELECT @PUId AS 'PUId',@Timestamp AS 'Timestamp',@Event_Id AS 'Event_Id'  
END  
RETURN  
  
