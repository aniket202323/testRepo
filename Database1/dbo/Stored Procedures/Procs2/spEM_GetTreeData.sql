CREATE PROCEDURE dbo.spEM_GetTreeData
  @User_Id 	 Int,
  @IsAdmin Int
  AS
  --
  -- Delcare local variables.
  --
  DECLARE 
 	  	 @Active 	  	 bit,
 	  	 @Corporate 	 Int,
 	  	 @LoadProd 	 Int,
 	  	 @PU 	  	 Int,
 	  	 @MU 	  	 Int,
 	  	 @EventStr 	 VarChar(7000),
 	  	 @ETId 	  	 Int,
 	  	 @Desc  	 nvarchar(50),
 	  	 @Old 	  	 Int,
 	  	 @HaveMaintenance 	 tinyint,
 	  	 @EnableBOM 	 Int,
 	  	 @TimeZone 	 nVarChar(200),
 	  	 @UseProficyClient 	 Int,
 	  	 @UseOEEAgg 	  	  	 Int
  -- 
  -- Determine the userid for this user.
  --
-- Licence resysn
-- Execute spEMML_ReSyncUsers @User_Id
--Variables Resync
IF EXISTS (SELECT 1 FROM Variables_Base a JOIN Variables_Aspect_EquipmentProperty e on e.Var_Id = a.Var_Id WHERE Var_Desc != Origin1Name  )
Begin
 	 UPDATE Variables_Base SET Var_Desc = Origin1Name 
 	  	 FROM Variables_Base a
 	  	 JOIN Variables_Aspect_EquipmentProperty e on e.Var_Id = a.Var_Id 
 	  	 WHERE Var_Desc != Origin1Name 
End
/* Purge Audit Trail  */
Declare @DaysToKeep Int,@ParmId  Int,@DisplaySOAUnit Int
Select @ParmId = Parm_Id From parameters where  Parm_Name = 'Audit Trail Purge Days'
If @ParmId is not null
  Begin
    Select @DaysToKeep = Convert(Int,Value) From Site_Parameters where Parm_Id = @ParmId and hostname = ''
    If @DaysToKeep > 0 and @DaysToKeep is not null
      Delete From Audit_Trail Where StartTime < DateAdd(Day,-@DaysToKeep,dbo.fnServer_CmnGetDate(getUTCdate())) and Application_Id = 1
  End
SET @UseProficyClient = 0
SET @ParmId = Null
Select @ParmId = Parm_Id From parameters where  Parm_Name = 'UseProficyClient'
If @ParmId is not null
  Begin
    Select @DisplaySOAUnit = Convert(Int,Value) From Site_Parameters where Parm_Id = @ParmId and hostname = ''
    SELECT @UseProficyClient = Coalesce(@DisplaySOAUnit,@UseProficyClient)
    IF @DisplaySOAUnit = 0 
 	 BEGIN
 	  	 SET @DisplaySOAUnit = -100
 	  	 DELETE FROM PlantAppsSOAPendingTasks
 	 END
 	 ELSE
 	  	 SET @DisplaySOAUnit = 0
  End
SET @ParmId = Null
Select @ParmId = Parm_Id From parameters where  Parm_Name = 'Populate OEE Aggregation'
If @ParmId is not null
  Begin
    Select @UseOEEAgg = Convert(Int,Value) From Site_Parameters where Parm_Id = @ParmId and hostname = ''
  End
SET @UseOEEAgg = Coalesce(@UseOEEAgg,0)
Select @EnableBOM = 0
-- Need to be Manager to objects 
If (select Count(*)
 	 from Bill_OF_Material_Family b
 	 Join User_Security s On b.Group_Id = s.Group_Id and s.User_Id = @User_Id and Access_Level > 2) > 0
 	 Select @EnableBOM = 1
If (select Count(*)
 	 from Bill_OF_Material b
 	 Join User_Security s On b.Group_Id = s.Group_Id and s.User_Id = @User_Id and Access_Level > 2) > 0
 	 Select @EnableBOM = 1
 	 
  --
  -- Return tree data...
  --
   -- Get   Event SubType Records
  SELECT  ET_Id,Event_Subtype_Id,Event_Subtype_Desc FROM  Event_Subtypes
   -- Get   SPC Calculation Type Records
  SELECT  SPC_Calculation_Type_Id, SPC_Calculation_Type_Desc from SPC_Calculation_Types
   -- Get   SPC Variable Type Records
  SELECT  SPC_Group_Variable_Type_Id, SPC_Group_Variable_Type_Desc from SPC_Group_Variable_Types
   -- Get   PrdExec Input Records
  SELECT  PEI_Id, Input_Name, Event_Subtype_Id, PU_Id FROM PrdExec_Inputs
   -- Get   Property Type Records
  SELECT  Property_Type_Id,Property_Type_Name FROM  Property_Types
   -- Get   Extended_Test_Freqs Type Records
  SELECT  Ext_Test_Freq_Id,Ext_Test_Freq_Desc FROM  Extended_Test_Freqs
   -- Get Sampling window type records
  SELECT Sampling_Window_Type_Id,Sampling_Window_Type_Name,Sampling_Window_Type_Data FROM Sampling_Window_Types ORDER BY Sampling_Window_Type_Name
  -- Get data source records.
  SELECT DS_Id, DS_Desc,Active,Bulk_Import = Coalesce(Bulk_Import,0) FROM Data_Source Where DS_Id <> 50000 ORDER BY DS_Desc
  -- Get operating system records.
  SELECT OS_Id, OS_Desc FROM Operating_Systems ORDER BY OS_Desc
  -- Get historian type records.
  SELECT Hist_Type_Id, Hist_Type_Desc FROM historian_types ORDER BY Hist_Type_Desc
  -- Get sampling type records.
  SELECT ST_Id, ST_Desc FROM Sampling_Type Where ST_Id <> 48 ORDER BY ST_Desc
  -- Get specification activation records.
  SELECT SA_Id, SA_Desc FROM Spec_Activations ORDER BY SA_Desc
  -- Get access level records.
  SELECT AL_Id, AL_Desc FROM Access_Level ORDER BY AL_Desc
  -- Get event type records
  SELECT ET_Id, ET_Desc FROM Event_Types WHERE Variables_Assoc > 0  ORDER BY ET_Desc
  --Get Event Status
  SELECT ProdStatus_Id,ProdStatus_Desc,LockData = isnull(LockData,0)   from Production_Status ORDER BY ProdStatus_Desc
  -- Get Server Specific Info
  Select @Corporate = Null
  Select @Corporate = Value  FROM site_parameters Where Parm_Id in (select Parm_Id From Parameters  Where Parm_Name = 'Corporate')
  Select @LoadProd = Null
  Select @LoadProd = Value  FROM site_parameters Where Parm_Id in (select Parm_Id From Parameters  Where Parm_Name = 'Load Product Families')
  If (Select count(*) from DB_Maintenance_Commands Where Executed_On is null) > 0
 	  	 select @HaveMaintenance = 1
  else
 	  	 select @HaveMaintenance = 0
  SELECT  Corporate = Case  When @Corporate is null Then 0
 	                         Else  @Corporate
 	  	          End,
 	    LoadProducts = Case  When @LoadProd is null Then 0
 	                         Else  @LoadProd
 	  	          End,
 	    ServerName = @@ServerName,
 	  	 Maintenance = @HaveMaintenance
  -- Get color scheme records.
  SELECT CS_Id, CS_Desc FROM Color_Scheme Order by CS_Desc
  -- Get user view Group.
  Select View_Group_Id,Group_Id,View_Group_Desc From view_groups
  -- Get user view records.
  SELECT View_Id, View_Desc,Group_Id,View_Group_Id,Toolbar_Version = coalesce(Toolbar_Version,'n/a')
 FROM Views Order by View_Desc
  -- Get data type records.
  SELECT Data_Type_Id, Data_Type_Desc, User_Defined, Use_Precision
    FROM Data_Type Where Data_type_Id <> 50
    Order by Data_Type_Desc
  -- Get phrase records.
--  SELECT Phrase_Id, Data_Type_Id, Phrase_Value, Phrase_Order, Active, Comment_Required FROM Phrase
  -- Get schedule status records.
  SELECT PPS.PP_Status_Id, PPS.PP_Status_Desc, C.Color_Id, C.Color_Desc, PPS.Movable,Allow_Edit = isnull(Allow_Edit,0)
    FROM Production_Plan_Statuses PPS
    LEFT OUTER JOIN Colors C on C.Color_Id = PPS.Color_Id
    Order by PPS.PP_Status_Desc
  -- Get user records, -- Get Security Roles.
 If ((Select Value from Site_Parameters Where Parm_Id = 60 and HostName = '') = 1) and (@IsAdmin = -1)
   Begin
    SELECT User_Id, RoleName = UserName, Active FROM Users Where Is_Role = 1 and User_Id != 49
    SELECT User_Desc = coalesce(User_Desc,''),a.User_Id, Username, Active, System, WindowsUserInfo = Coalesce(WindowsUserInfo, ''), 
 	  	  	 Is_Role, Role_Based_Security, Mixed_Mode_Login, UseSSO=Coalesce(UseSSO,0), SSOUserId=Coalesce(SSOUserId,''), inSOA = Case WHEN b.User_Id is null then 0 else 1 end
 	  	  	 FROM Users a
 	  	  	 Left Join Users_Aspect_Person b on b.User_Id = a.user_Id
 	  	  	 Where Is_Role = 0
 	  	  	 Order by Username
    SELECT Group_Id, Group_Desc, Comment_Id, External_Link FROM Security_Groups order by  Group_Desc
    SELECT Security_Id, Group_Id, us.User_Id, Access_Level, u.Is_Role
      FROM User_Security us
      JOIN Users u ON u.User_Id = us.User_Id
      WHERE us.user_id = @User_Id and U.Role_Based_Security = 0 Order by Group_Id,Username
   End
  Else 
   IF @IsAdmin = -1
    Begin
     SELECT User_Id, RoleName = UserName, Active FROM Users Where Is_Role = 1
     SELECT User_Desc = coalesce(User_Desc,''),a.User_Id, Username, Active, 
 	  	  	 System, WindowsUserInfo = Coalesce(WindowsUserInfo, ''), Is_Role, 
 	  	  	 Role_Based_Security, Mixed_Mode_Login ,UseSSO=Coalesce(UseSSO,0), SSOUserId=Coalesce(SSOUserId,''),inSOA = Case WHEN b.User_Id is null then 0 else 1 end
 	 FROM Users  a
 	 Left Join Users_Aspect_Person b on b.User_Id = a.user_Id
 	 Where System = 0 and Is_Role = 0 
 	 Order by Username
     SELECT Group_Id, Group_Desc, Comment_Id, External_Link FROM Security_Groups order by  Group_Desc
     SELECT Security_Id, Group_Id, us.User_Id, Access_Level, u.Is_Role
      FROM User_Security us
      JOIN Users u ON u.User_Id = us.User_Id
      WHERE us.user_id = @User_Id and  U.Role_Based_Security = 0 Order by Group_Id,Username
    End
   Else
    Begin
      SELECT User_Id, RoleName = UserName, Active FROM Users Where Is_Role = 1
      SELECT User_Desc = coalesce(User_Desc,''),User_Id, Username, Active, System, 
      WindowsUserInfo = Coalesce(WindowsUserInfo, ''), Is_Role, 
      Role_Based_Security, Mixed_Mode_Login,UseSSO=Coalesce(UseSSO,0), SSOUserId=Coalesce(SSOUserId,''),inSOA =  1
      FROM Users Where System = 0 and  user_id = @User_Id
      SELECT Group_Id, Group_Desc, Comment_Id, External_Link 
 	 FROM Security_Groups
 	 order by  Group_Desc
      SELECT Security_Id, Group_Id, us.User_Id, Access_Level, u.Is_Role
        FROM User_Security us
        JOIN Users u ON u.User_Id = us.User_Id
        WHERE us.user_id = @User_Id and U.Role_Based_Security = 0 
    End
  -- Get Security Role Members.
  IF @IsAdmin = -1
   Begin
     SELECT Distinct User_Role_Security_Id, Role_User_Id, User_Id = 0, GroupName = Coalesce(GroupName, ''), Domain = Coalesce(Domain, '') 
       FROM User_Role_Security Where User_Id is NULL
   UNION
     SELECT Distinct User_Role_Security_Id, Role_User_Id, u.User_Id, GroupName = Coalesce(u.UserName, ''), Domain = Coalesce(Domain, '')
       FROM User_Role_Security ur
         JOIN Users u on u.User_Id = ur.User_Id
       Order By GroupName
   End
  Else
   Begin
     SELECT Distinct User_Role_Security_Id, Role_User_Id, User_Id = 0, GroupName = Coalesce(GroupName, ''), Domain = Coalesce(Domain, '') 
       FROM User_Role_Security Where User_Id is NULL
   UNION
     SELECT Distinct User_Role_Security_Id, Role_User_Id, u.User_Id, GroupName = Coalesce(u.UserName, ''), Domain = Coalesce(Domain, '') 
       FROM User_Role_Security ur
         JOIN Users u on u.User_Id = ur.User_Id
         WHERE u.User_Id = @User_Id
       Order By GroupName
   End
   -- Get transaction Group records.
  SELECT Transaction_Grp_Id, Transaction_Grp_Desc FROM Transaction_Groups Order By Transaction_Grp_Desc
  -- Get transaction records.
  SELECT Trans_Id, Trans_Desc, Approved_By, Comment_Id,Trans_Type_Id
 	  FROM Transactions
 	  WHERE Approved_By IS NULL and Linked_Server_Id is Null
 	 Order by Trans_Desc
  If (Select Count(*) from Prod_Lines where Dept_Id is null) > 0 
 	 Update  Prod_Lines Set Dept_Id = (select Min(Dept_Id) From Departments)  where Dept_Id is null
  Select a.Dept_Id, Dept_Desc, Comment_Id, Extended_Info,Time_Zone,inSOA = Case WHEN b.Dept_Id is null then 0 else 1 end
   from Departments a
   LEFT Join PAEquipment_Aspect_SOAEquipment b ON a.Dept_Id = b.Dept_Id 
   WHERE a.Dept_Id Not in (0,@DisplaySOAUnit)
   ORDER BY Dept_Desc ASC
 -- Get production line records.
  SELECT a.Dept_Id, a.PL_Id, PL_Desc, Group_Id, Comment_Id, Extended_Info, External_Link,inSOA = Case WHEN b.Pl_Id is null then 0 else 1 end
    FROM Prod_Lines a
   LEFT Join PAEquipment_Aspect_SOAEquipment b ON a.Pl_Id = b.pl_Id 
    WHERE a.PL_Id Not in (0,@DisplaySOAUnit)
    Order By PL_Desc
  -- Get production unit records. (Join Prod_Events for Trees)
  Create Table #ProdUnits (PU_Id Int, PU_Desc nvarchar(50),Master_order Int, PU_Order Int, PL_Id Int, Master_Unit Int, Group_Id Int,
 	  	  	  	  	  	    Comment_Id Int, Extended_Info nvarchar(255), External_Link nvarchar(255),Waste_TN_Id Int,Timed_TN_Id Int,
 	  	  	  	  	  	   Timed_Event_Association Int,Uses_Start_Time Int,BOMSPECS Int)
  Insert into #ProdUnits(PU_Id, PU_Desc,Master_order,PU_Order,PL_Id, Master_Unit, Group_Id,Comment_Id,Extended_Info,External_Link,Waste_TN_Id,
 	  	  	  	  	  	  Timed_TN_Id,Timed_Event_Association,Uses_Start_Time,BOMSPECS)
  SELECT pu.PU_Id, PU_Desc, 	 Master_order= case When (Master_Unit IS Null) and (PU_Order is NuLL)   Then  pu.PU_Id
 	  	  	  	  	       When (Master_Unit IS Not Null) and (select PU_Order from prod_units where pu_Id = pu.Master_Unit) is Null Then pu.Master_Unit
  	   	  	  	  	       When Master_Unit IS Null  Then PU_Order
 	  	  	  	  	       Else (select convert(Int,PU_Order) from prod_units where pu_Id = pu.Master_Unit) 
 	  	  	  	  	       End ,
 	  PU_Order , pu.PL_Id, Master_Unit, Group_Id, Comment_Id, Extended_Info, External_Link,
 	  Waste_TN_Id = pe2.Name_Id,Timed_TN_Id = pe.Name_Id,Timed_Event_Association = Coalesce(pu.Timed_Event_Association,0),
 	  Uses_Start_Time = Coalesce(pu.Uses_Start_Time,0),0
    FROM Prod_Units pu
    LEFT JOIN Prod_Events pe  ON  pe.PU_Id = pu.PU_Id AND pe.Event_type = 2    -- Delay (timed)
    LEFT JOIN Prod_Events pe2 ON pe2.PU_Id = pu.PU_Id AND pe2.Event_type = 3   -- Waste 
    WHERE pu.PU_Id Not in (0,@DisplaySOAUnit)
  Update #ProdUnits Set BOMSPECS = 1 
 	 From #ProdUnits
 	 Join Prod_Units pu on #ProdUnits.pu_Id =  Coalesce(pu.Master_Unit,pu.pu_Id)
    Join Variables v on v.pu_Id = pu.Pu_Id
 	 Join Specifications s on s.spec_Id = v.Spec_Id
 	 Join Product_Properties pp on pp.Prop_Id = s.Prop_Id and  pp.Property_Type_Id = 2
  Select a.PU_Id, PU_Desc,Master_order,PU_Order,a.PL_Id, Master_Unit, Group_Id,Comment_Id,Extended_Info,External_Link,Waste_TN_Id,
 	  	  	  	  	  	  Timed_TN_Id,Timed_Event_Association,Uses_Start_Time,BOMSPECS,inSOA = Case WHEN b.pu_Id is null then 0 else 1 end
   from #ProdUnits a
    LEFT Join PAEquipment_Aspect_SOAEquipment b ON a.Pu_Id = b.pu_Id 
  ORDER BY a.PL_Id,Master_order,Master_Unit,PU_Order
  Drop Table #ProdUnits
  -- Get production group records.
  SELECT PUG_Id, PU_Id,Group_Id, PUG_Desc, PUG_Order, Comment_Id, External_Link
    FROM PU_Groups
    WHERE PUG_Id Not in (0,@DisplaySOAUnit)  and PUG_Desc <> 'Model 5014 Calculation'
    ORDER BY PUG_Order, PUG_Desc
  -- Get property records
  Update Product_Properties set Property_Type_Id = 1 where Property_Type_Id is null
  SELECT Prop_Id, Prop_Desc, Comment_Id, Group_Id, External_Link,Property_Type_Id,Product_Family_Id,Auto_Sync_Chars
    FROM Product_Properties Order By  Prop_Desc
  Create Table #HistorianPW(Hist_Id Int,  Hist_Password  nvarchar(255))
  Execute spCmn_GetHistorianPWData2 'EncrYptoR'
  SELECT h.Hist_Id, Hist_Servername = Coalesce(Hist_Servername,''), Hist_Username, hp.Hist_Password, Hist_Default, Hist_OS_Id,Hist_Type_Id,Alias
 	  	 FROM Historians  h
 	 Join #HistorianPW hp on hp.Hist_Id = h.Hist_Id
 	  Order By  Hist_Servername
  Drop table #HistorianPW
  -- Get Displays.
  SELECT Sheet_Type_Id,Sheet_Type_Desc,App_Id  From Sheet_Type st
 	  Where Is_Active = 1
 	  order by Sheet_Type_Desc 
  SELECT Sheet_Group_Id,Sheet_Group_Desc,Group_Id From Sheet_Groups Order By Sheet_Group_Desc
  Select Product_Family_Id,Product_Family_Desc,External_Link,Comment_Id,Group_Id 
 	 From Product_Family Order By Product_Family_Desc
  Select * from Product_Groups  Order By Product_Grp_Desc
  Create Table #CO(Comparison_Operator_Id Int,Comparison_Operator_Value nVarChar(25))
  Insert INto #CO (Comparison_Operator_Id,Comparison_Operator_Value)
   	 select Comparison_Operator_Id,Comparison_Operator_Value from Comparison_Operators
  Insert Into #CO (Comparison_Operator_Id,Comparison_Operator_Value) Values (0,'<None>')
  Select * From #CO
  Drop Table #CO
  Select ER_Id,ER_Address,ER_Desc,Is_Active,Standard_Header_Mode = isnull(Standard_Header_Mode,0) From Email_Recipients order by ER_Desc
  Select EG_Id,EG_Desc from Email_Groups where EG_Id <> 50 order by EG_Desc
  Select EG_Id,ER_Id,EGR_Id From Email_Groups_Data
  Select ERC_Id,ERC_Desc,[System] = case When ERC_Id < 100 Then 1 Else 0 End
 From Event_Reason_Catagories Where ERC_Id <> 100 order by ERC_Desc
 	 
SELECT Eng_Unit_Id,Eng_Unit_Desc,Eng_Unit_Code 
 	 from Engineering_Unit
 	 where Eng_Unit_Id <> 50000
 	 order by Eng_Unit_Desc
Select Subscription_Group_Id,Subscription_Group_Desc,Priority,Stored_Procedure_Name
 	  from Subscription_Group
 	 Order by Priority
Select Subscription_Group_Id,Subscription_Id,Subscription_Desc,Time_Trigger_Interval,Time_Trigger_Offset,Is_Active,Table_Id,
 	  	 KeyInfo = Case When Table_Id = 1 then '<' + Convert(nVarChar(10),Key_Id) + '> ' + (Select  PU_Desc From Prod_Units where PU_Id = Key_Id)
 	  	  	  	  	 When Table_Id = 7 then '<' + Convert(nVarChar(10),Key_Id) + '> ' + (Select  Path_Desc From PrdExec_Paths where Path_Id = Key_Id)
 	  	  	  	 End
  	  from Subscription
 	 Order by Subscription_Desc
select Eng_Unit_Conv_Id,Conversion_Desc,From_Eng_Unit_Id,To_Eng_Unit_Id,[Slope] = isnull(Slope,0),[Intercept] = isnull(Intercept,0)
 From Engineering_Unit_Conversion
 where Eng_Unit_Conv_Id <> 50000 and From_Eng_Unit_Id is not null and To_Eng_Unit_Id is not null and Conversion_Desc is not Null
 Order by Conversion_Desc
Select BOMSecurity = @EnableBOM
SELECT @TimeZone = Value FROM Site_Parameters WHERE Parm_Id = 192
IF Exists(SELECT 1 FROM TimeZoneTranslations WHERE TimeZone = @TimeZone)
 	 SELECT DataBaseTimeZoneOk = 1
ELSE
 	 SELECT DataBaseTimeZoneOk = 0
SELECT UseProficyClient = @UseProficyClient,UseOEEAgg = @UseOEEAgg
