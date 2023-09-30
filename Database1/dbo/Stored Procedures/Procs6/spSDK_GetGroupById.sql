CREATE PROCEDURE dbo.spSDK_GetGroupById
 	 @MessageType INT,
 	 @KeyName nvarchar(50),
 	 @GroupId INT OUTPUT
AS
--MessageType
--sdkRTVariableResult = 1
--sdkRTProductionEvent = 2
--sdkRTGenealogyLink = 4
--sdkRTDowntime = 9
--sdkRTWaste = 10
--sdkRTVariableAlarm = 14
--sdkRTUserDefinedEvent = 15
IF @MessageType = 1 or @MessageType = 14 --sdkRTVariableResult, sdkRTVariableAlarm
 	 BEGIN
 	  	 SELECT @GroupId = Group_Id
 	  	  	 FROM Variables
 	  	  	 WHERE Var_Desc = LTrim(RTrim(@KeyName))
 	  	 IF @GroupId IS NULL
 	  	  	 SELECT @GroupId = pug.Group_Id
 	  	  	  	 FROM PU_Groups pug
 	  	  	  	 JOIN Variables v ON v.PUG_Id = pug.PUG_Id
 	  	  	  	 WHERE v.Var_Desc = LTrim(RTrim(@KeyName))
 	  	 IF @GroupId IS NULL
 	  	  	 SELECT @GroupId = pu.Group_Id
 	  	  	  	 FROM Prod_Units pu
 	  	  	  	 JOIN Variables v ON v.PU_Id = pu.PU_Id
 	  	  	  	 WHERE v.Var_Desc = LTrim(RTrim(@KeyName))
 	  	 IF @GroupId IS NULL
 	  	  	 SELECT @GroupId = Coalesce(pl.Group_Id, 0)
 	  	  	  	 FROM Prod_Lines pl
 	  	  	  	 JOIN Prod_Units pu ON pu.PL_Id = pl.PL_Id
 	  	  	  	 JOIN Variables v ON v.PU_Id = pu.PU_Id
 	  	  	  	 WHERE v.Var_Desc = LTrim(RTrim(@KeyName))
 	 END
IF @MessageType = 2 or @MessageType = 4 or @MessageType = 9 or @MessageType = 10 or @MessageType = 15
  --sdkRTProductionEvent, sdkRTGenealogyLink, sdkRTDowntime, sdkRTWaste, sdkRTUserDefinedEvent
 	 BEGIN
 	  	 SELECT @GroupId = Group_Id
 	  	  	 FROM Prod_Units
 	  	  	 WHERE PU_Desc = LTrim(RTrim(@KeyName))
 	  	 IF @GroupId IS NULL
 	  	  	 SELECT @GroupId = Coalesce(pl.Group_Id, 0)
 	  	  	  	 FROM Prod_Lines pl
 	  	  	  	 JOIN Prod_Units pu ON pu.PL_Id = pl.PL_Id
 	  	  	  	 WHERE pu.PU_Desc = LTrim(RTrim(@KeyName))
 	 END
IF @MessageType = 5 --sdkRTProductChange
        BEGIN
 	  	 SELECT @GroupId = pf.Group_Id
 	  	  	 FROM Product_Family pf
                        Join Products p on p.Product_Family_Id = pf.Product_Family_Id
 	  	  	 WHERE p.Prod_Code = LTrim(RTrim(@KeyName))
        END
