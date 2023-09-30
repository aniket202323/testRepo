CREATE PROCEDURE dbo.spSDK_CheckConnection
 	 @ConnectionName 	 nvarchar(100),
 	 @Reload 	  	  	  	 INT  	  	  	  	 OUTPUT
AS
-- Return Values
-- 0 - Success
SELECT 	 @Reload = 0
DECLARE 	 @ConnectionId 	 nvarchar(100)
--Check If Connection With This Name Already Exists
SELECT 	 @ConnectionId = NULL
SELECT 	 @ConnectionId = Name 
 	 FROM 	 GWay_Permanent_Clients 
 	 WHERE Name = @ConnectionName
IF @ConnectionId IS NULL
BEGIN
    --We Need To Add The Connection
 	 INSERT INTO 	 GWay_Permanent_Clients(Name,Is_Active) 
 	  	 VALUES 	 (@ConnectionName,1)    
 	 SELECT 	 @Reload = 1
END ELSE
BEGIN
    -- No Need To Reload
 	 SELECT @Reload = 0
END
RETURN(0)
