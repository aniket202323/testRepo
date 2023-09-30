/*declare @xml xml = '<units userId="55">
<unit id="1" unitName="unit1" eventId="2"  transactiontype="1"/> transactiontype 1 - insert ,2-delete 
<unit id="2" unitName="unit2" eventId="2" transactiontype="1"/>
<unit id="3" unitName="unit3" eventId="2"  transactiontype="2"/>
</units>'
SELECT x.y.value('@id','int'),x.y.value('@unitname','nvarchar(1000)') 
FROM @xml.nodes('Units/Unit') as x(y) */
CREATE PROCEDURE [dbo].[spBF_APIMyMachines_AddUpdateDeletePreferencesperUser]
@Recordxml xml
AS
BEGIN
DECLARE @AvailableUnitslist Table (Id int Identity(1,1),PU_Id Int , PU_Desc nVarChar(max), PL_Id Int, PL_Desc nVarChar(max), Dept_Id Int, Dept_Desc nVarChar(max),  ET_Id Int , ET_Desc nvarchar(1000),Access_level int)
DECLARE @inputtable TABLE (Id INT Identity(1,1),Pu_Id INT, Pu_desc nvarchar(1000),ET_Id INT,user_id INT,TransactionType INT)
DECLARE @UserIdlist TABLE (UserId INT)
DECLARE @intErrorCode INT
DECLARE @UserId INT 
INSERT INTO @userIdlist(userId) SELECT x.y.value('@userId','int') FROM @Recordxml.nodes('units') as x(y)
IF (SELECT count(*) FROM @userIdList) > 1
 	 BEGIN
 	  	 SELECT Errorcode ='MultipleUsersFoundInInputListNotSupportedNow'
 	  	 RETURN
 	 END
 	 
 	 
SELECT @UserId=userId FROM @userIdList
INSERT INTO @AvailableUnitslist ( Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Desc, ET_Id,ET_Desc,Access_level)
SELECT Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Desc, ET_Id,ET_Desc,Access_level FROM dbo.fnBF_ApiFindAvailableUnitsAndEventTypes(
@UserId)
--transform the xml into a table 
INSERT INTO @inputtable (Pu_Id,Pu_desc,ET_Id,TransactionType)
SELECT x.y.value('@id','int'),x.y.value('@unitName','nvarchar(1000)'),x.y.value('@eventId','int'), x.y.value('@transactiontype','int')
FROM @Recordxml.nodes('units/unit') as x(y)
IF ((Select 1 from @inputtable where Pu_Id not in (Select pu_id from dbo.Prod_Units_Base )) > 0)
 	 OR ((Select Count(*) from @inputtable where Pu_Id not in (Select pu_id from @AvailableUnitslist )) > 0)
 	 BEGIN
 	  	 SELECT Errorcode ='InvalidUnitsInInput'
 	  	 RETURN
 	 END
 	 
IF EXISTS (Select pu_id,ET_id ,count(*) from @inputtable group by pu_id,et_id having count(*) > 1)
 	 BEGIN
 	  	 SELECT Errorcode ='InvalidUnitsInInput'
 	  	 RETURN
 	 END
Update @inputtable set user_id = (SELECT Top 1 userId FROM @UserIdlist)
BEGIN TRAN
--for the userid , delete the previous selection
Delete FROM User_UnitPreferences WHERE user_id =  (SELECT DISTINCT user_id FROM @inputtable) and Profile_id = -1
SELECT @intErrorCode = @@ERROR
    IF (@intErrorCode <> 0) GOTO PROBLEM
--update the current selection as previous profile i.e. -1
UPDATE User_UnitPreferences set profile_id = -1  WHERE user_id =  (SELECT DISTINCT user_id FROM @inputtable) and Profile_id = 0
SELECT @intErrorCode = @@ERROR
    IF (@intErrorCode <> 0) GOTO PROBLEM
--now insert the new rows as current preference 
INSERT INTO User_UnitPreferences (user_id,pu_id,et_id,modified_on,profile_id)
SELECT user_id,pu_id,et_id,dbo.fnServer_CmnGetDate(GETUTCDATE()),0 FROM @inputtable WHERE TransactionType = 1
SELECT @intErrorCode = @@ERROR
    IF (@intErrorCode <> 0) GOTO PROBLEM
COMMIT TRAN
GOTO SPROCEND
PROBLEM:
IF (@intErrorCode <> 0) BEGIN
SELECT Errorcode ='UnexpectedErrorOccurred'
    ROLLBACK TRAN
 	 RETURN
END
SPROCEND:
SELECT dt.dept_id,dt.dept_desc,
 	    pl.pl_id,pl_desc,
 	    pu.pu_id,pu.pu_desc,
 	    et.ET_Id ,et.et_desc,
 	    user_id
FROM dbo.User_UnitPreferences up
join dbo.prod_units pu on up.pu_id =  pu.pu_id
join dbo.prod_lines  pl on pu.pl_id = pl.pl_id
join dbo.Departments dt on pl.dept_id = dt.dept_id
join dbo.event_types et on up.et_id = et.et_id
 WHERE user_id = (SELECT DISTINCT user_id FROM @inputtable)  and profile_id = 0
END
