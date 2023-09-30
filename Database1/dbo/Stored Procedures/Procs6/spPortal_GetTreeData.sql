-- spPortal_GetTreeData is derived from spEM_GetTreeData. "Real Time Information Portal" (RTIP) (formerly InfoAgent)
-- use this SP to build tree model similar to that Plant Applications Administrator. But RTIP wants its own SP so as
-- to maintain optimum compatiblity (spEM_GetTreeData is like to change to suit Administrator module, which will likely
-- break compatibility )
-- Information Sought: 
   -- Departments: 	 Dept_Id 	  	 Dept_Desc 	 
   -- Lines: 	  	 Dept_Id 	  	 Line_Id 	  	 Line_Desc 	 
   -- Units: 	  	 PU_Id 	  	 PU_Desc 	  	 PL_Id 	  	 Master_Unit
   -- Variable Groups: 	 PUG_Id 	  	 PUG_Desc 	 PU_Id
   -- Product Families: 	 Product_Family_Id 	  	 Product_Family_Desc
   -- Product Groups: 	 Product_Grp_Id 	 Product_Grp_Desc
   -- List Properties: 	 Prop_Id 	  	 Prop_Desc
--
CREATE PROCEDURE dbo.spPortal_GetTreeData 
 	   @User_Id 	 Int
 	 --, @IsAdmin 	 Int
  AS
  -- 1) Get Departments records
  SELECT Dept_Id, Dept_Desc FROM Departments ORDER BY Dept_Desc
  -- 2) Get production line records.
  SELECT Dept_Id, PL_Id, PL_Desc FROM Prod_Lines WHERE PL_Id > 0 ORDER BY PL_Desc   -- restored : mt/2-16-2005
  -- 3) Get production unit records: PU_Id, PU_Desc, PL_Id, Master_Unit
   SELECT pu.PU_Id, PU_Desc, PL_Id, Master_Unit
     FROM Prod_Units pu
    WHERE pu.PU_Id > 0 
  -- 4) Get production group records.
  SELECT PUG_Id, PU_Id, PUG_Desc FROM PU_Groups WHERE PUG_Id > 0 ORDER BY PUG_Desc
  -- 5) Get property records
  SELECT Prop_Id, Prop_Desc FROM Product_Properties ORDER BY Prop_Desc
  -- 6) Get Product_Family_Id, Product_Family_Desc
  SELECT Product_Family_Id, Product_Family_Desc FROM Product_Family ORDER BY Product_Family_Desc
  -- 7) Get Product_Grp_Id, Product_Grp_Desc
  SELECT Product_Grp_Id, Product_Grp_Desc FROM Product_Groups ORDER BY Product_Grp_Desc
/* ECR #29631
   Disabled per Dave Haines Review mt/4-25-2005
   Problems with 50,000 variables
   Let spPortal_LoadInformation handle getting variables and products when needed.
-- 8) Get ALL variables
  SELECT Var_Id, Var_Desc, PU_Id, PUG_Id, PVar_Id, Eng_Units
    FROM Variables
   WHERE PU_Id <> 0
ORDER BY Var_Desc
    --{ ECR #29595 - Performance Enhancement, products stay in memory until needed later 
-- 9) Get products for use later as needed
  SELECT Prod_Id, Prod_Desc, Prod_Code, Product_Family_Id
    FROM Products 
   WHERE Prod_Id <> 1 
ORDER BY Prod_Code
*/
-- **************** BELOW ARE ORIGINAL spPortal_GetTreeInformation  which is derived from spEM_GetTreeInformation used in PlantApps Administrator MODULE *************
-- **************** BELOW ARE ORIGINAL spPortal_GetTreeInformation  which is derived from spEM_GetTreeInformation used in PlantApps Administrator MODULE *************
-- **************** BELOW ARE ORIGINAL spPortal_GetTreeInformation  which is derived from spEM_GetTreeInformation used in PlantApps Administrator MODULE *************
-- **************** BELOW ARE ORIGINAL spPortal_GetTreeInformation  which is derived from spEM_GetTreeInformation used in PlantApps Administrator MODULE *************
-- **************** BELOW ARE ORIGINAL spPortal_GetTreeInformation  which is derived from spEM_GetTreeInformation used in PlantApps Administrator MODULE *************
-- **************** BELOW ARE ORIGINAL spPortal_GetTreeInformation  which is derived from spEM_GetTreeInformation used in PlantApps Administrator MODULE *************
-- **************** BELOW ARE ORIGINAL spPortal_GetTreeInformation  which is derived from spEM_GetTreeInformation used in PlantApps Administrator MODULE *************
  --
  -- Delcare local variables.
  --
  -- 
  -- Determine the userid for this user.
  --
/* Purge Audit Trail  */
/*
Declare @DaysToKeep Int,@ParmId  Int
Select @ParmId = Parm_Id From parameters where  Parm_Name = 'Audit Trail Purge Days'
If @ParmId is not null
  Begin
    Select @DaysToKeep = Convert(Int,Value) From Site_Parameters where Parm_Id = @ParmId and hostname = ''
    If @DaysToKeep > 0 and @DaysToKeep is not null
      Delete From Audit_Trail Where StartTime < DateAdd(Day,-@DaysToKeep,getdate()) and Application_Id = 1
  End
*/
  --
  -- Return tree data...
  --
   -- Get   Event SubType Records
--  SELECT  ET_Id,Event_Subtype_Id,Event_Subtype_Desc FROM  Event_Subtypes
   -- Get   SPC Calculation Type Records
--  SELECT  SPC_Calculation_Type_Id, SPC_Calculation_Type_Desc from SPC_Calculation_Types
   -- Get   SPC Variable Type Records
--  SELECT  SPC_Group_Variable_Type_Id, SPC_Group_Variable_Type_Desc from SPC_Group_Variable_Types
   -- Get   PrdExec Input Records
--  SELECT  PEI_Id, Input_Name, Event_Subtype_Id, PU_Id FROM PrdExec_Inputs
   -- Get   Property Type Records
--  SELECT  Property_Type_Id,Property_Type_Name FROM  Property_Types
   -- Get   Extended_Test_Freqs Type Records
--  SELECT  Ext_Test_Freq_Id,Ext_Test_Freq_Desc FROM  Extended_Test_Freqs
   -- Get Sampling window type records
--  SELECT Sampling_Window_Type_Id,Sampling_Window_Type_Name,Sampling_Window_Type_Data FROM Sampling_Window_Types ORDER BY Sampling_Window_Type_Name
  -- Get data source records.
--  SELECT DS_Id, DS_Desc,Active,Bulk_Import = Coalesce(Bulk_Import,0) FROM Data_Source ORDER BY DS_Desc
  -- Get operating system records.
--  SELECT OS_Id, OS_Desc FROM Operating_Systems ORDER BY OS_Desc
  -- Get historian type records.
--  SELECT Hist_Type_Id, Hist_Type_Desc FROM historian_types ORDER BY Hist_Type_Desc
  -- Get sampling type records.
--  SELECT ST_Id, ST_Desc FROM Sampling_Type ORDER BY ST_Desc
  -- Get specification activation records.
--  SELECT SA_Id, SA_Desc FROM Spec_Activations ORDER BY SA_Desc
  -- Get access level records.
--  SELECT AL_Id, AL_Desc FROM Access_Level ORDER BY AL_Desc
  -- Get event type records
--  SELECT ET_Id, ET_Desc FROM Event_Types WHERE Variables_Assoc > 0  ORDER BY ET_Desc
  --Get Event Status
--  SELECT ProdStatus_Id,ProdStatus_Desc   from Production_Status ORDER BY ProdStatus_Desc
  -- Get Server Specific Info
/*
  Select @Corporate = Null
  Select @Corporate = Value  FROM site_parameters Where Parm_Id in (select Parm_Id From Parameters  Where Parm_Name = 'Corporate')
  Select @LoadProd = Null
  Select @LoadProd = Value  FROM site_parameters Where Parm_Id in (select Parm_Id From Parameters  Where Parm_Name = 'Load Product Families')
  If (Select count(*) from DB_Maintenance_Commands Where Executed_On is null) > 0
 	  	 select @HaveMaintenance = 1
  else
 	  	 select @HaveMaintenance = 0
  --EndIf
  SELECT  Corporate = Case  When @Corporate is null Then 0 Else  @Corporate End
        , LoadProducts = Case  When @LoadProd is null Then 0 Else  @LoadProd End
        , ServerName = @@ServerName
        , Maintenance = @HaveMaintenance
*/
  -- Get color scheme records.
--  SELECT CS_Id, CS_Desc FROM Color_Scheme Order by CS_Desc
  -- Get user view Group.
--  Select View_Group_Id,Group_Id,View_Group_Desc From view_groups
  -- Get user view records.
/*
  SELECT View_Id, View_Desc,Group_Id,View_Group_Id,Toolbar_Version = coalesce(Toolbar_Version,'n/a')
 FROM Views Order by View_Desc
*/
  -- Get data type records.
/*
  SELECT Data_Type_Id, Data_Type_Desc, User_Defined, Use_Precision
    FROM Data_Type Where Data_type_Id <> 50 Order by Data_Type_Desc
*/
  -- Get schedule status records.
/*
  SELECT PPS.PP_Status_Id, PPS.PP_Status_Desc, C.Color_Id, C.Color_Desc, PPS.Movable
    FROM Production_Plan_Statuses PPS
    LEFT OUTER JOIN Colors C on C.Color_Id = PPS.Color_Id
    Order by PPS.PP_Status_Desc
*/
  -- Get user records, -- Get Security Roles.
/*
 If ((Select Value from Site_Parameters Where Parm_Id = 60 and HostName = '') = 1) and (@IsAdmin = -1)
   Begin
    SELECT User_Id, RoleName = UserName, Active FROM Users Where Is_Role = 1
    SELECT User_Desc = coalesce(User_Desc,''),User_Id, Username, Active, System, WindowsUserInfo = Coalesce(WindowsUserInfo, ''), Is_Role, Role_Based_Security, Mixed_Mode_Login FROM Users Where Is_Role = 0 Order by Username
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
     SELECT User_Desc = coalesce(User_Desc,''),User_Id, Username, Active, System, WindowsUserInfo = Coalesce(WindowsUserInfo, ''), Is_Role, Role_Based_Security, Mixed_Mode_Login FROM Users Where System = 0 and Is_Role = 0 Order by Username
     SELECT Group_Id, Group_Desc, Comment_Id, External_Link FROM Security_Groups order by  Group_Desc
     SELECT Security_Id, Group_Id, us.User_Id, Access_Level, u.Is_Role
      FROM User_Security us
      JOIN Users u ON u.User_Id = us.User_Id
      WHERE us.user_id = @User_Id and  U.Role_Based_Security = 0 Order by Group_Id,Username
    End
   Else
    Begin
      SELECT User_Id, RoleName = UserName, Active FROM Users Where Is_Role = 1
      SELECT User_Desc = coalesce(User_Desc,''),User_Id, Username, Active, System, WindowsUserInfo = Coalesce(WindowsUserInfo, ''), Is_Role, Role_Based_Security, Mixed_Mode_Login FROM Users Where System = 0 and  user_id = @User_Id
      SELECT Group_Id, Group_Desc, Comment_Id, External_Link 
 	 FROM Security_Groups
 	 order by  Group_Desc
      SELECT Security_Id, Group_Id, us.User_Id, Access_Level, u.Is_Role
        FROM User_Security us
        JOIN Users u ON u.User_Id = us.User_Id
        WHERE us.user_id = @User_Id and U.Role_Based_Security = 0 
    End
*/
  -- Get Security Role Members.
/*
  IF @IsAdmin = -1
   Begin
     SELECT Distinct User_Role_Security_Id, Role_User_Id, User_Id = 0, GroupName = Coalesce(GroupName, '') 
       FROM User_Role_Security Where User_Id is NULL
   UNION
     SELECT Distinct User_Role_Security_Id, Role_User_Id, u.User_Id, GroupName = Coalesce(u.UserName, '')
       FROM User_Role_Security ur
         JOIN Users u on u.User_Id = ur.User_Id
       Order By GroupName
   End
  Else
   Begin
     SELECT Distinct User_Role_Security_Id, Role_User_Id, User_Id = 0, GroupName = Coalesce(GroupName, '') 
       FROM User_Role_Security Where User_Id is NULL
   UNION
     SELECT Distinct User_Role_Security_Id, Role_User_Id, u.User_Id, GroupName = Coalesce(u.UserName, '')
       FROM User_Role_Security ur
         JOIN Users u on u.User_Id = ur.User_Id
         WHERE u.User_Id = @User_Id
       Order By GroupName
   End
*/
   -- Get transaction Group records.
--  SELECT Transaction_Grp_Id, Transaction_Grp_Desc FROM Transaction_Groups Order By Transaction_Grp_Desc
  -- Get transaction records.
/*
  SELECT Trans_Id, Trans_Desc, Approved_By, Comment_Id,Trans_Type_Id
 	  FROM Transactions
 	  WHERE Approved_By IS NULL and Linked_Server_Id is Null
 	 Order by Trans_Desc
  If (Select Count(*) from Prod_Lines where Dept_Id is null) > 0 
 	 Update  Prod_Lines Set Dept_Id = (select Min(Dept_Id) From Departments)  where Dept_Id is null
  Select Dept_Id, Dept_Desc from Departments
*/
  -- ( Portal 1 ) Get Departments records
--  SELECT Dept_Id, Dept_Desc FROM Departments ORDER BY Dept_Desc
  -- ( Portal 2 ) Get production line records.
--  SELECT Dept_Id, PL_Id, PL_Desc FROM Prod_Lines WHERE PL_Id > 0 ORDER BY PL_Desc
/*
   SELECT Dept_Id, PL_Id, PL_Desc, Group_Id, Comment_Id, Extended_Info, External_Link
     FROM Prod_Lines
    WHERE PL_Id > 0
 ORDER BY PL_Desc
*/
  -- Get production unit records. (Join Prod_Events for Trees)
/*
  CREATE TABLE #ProdUnits (PU_Id Int, PU_Desc VarChar(50),Master_order Int, PU_Order Int, PL_Id Int, Master_Unit Int, Group_Id Int
                         , Comment_Id Int, Extended_Info VarChar(255), External_Link VarChar(255),Waste_TN_Id Int,Timed_TN_Id Int
                         , Timed_Event_Association Int,Uses_Start_Time Int,BOMSPECS Int)
  Insert into #ProdUnits(PU_Id, PU_Desc,Master_order,PU_Order,PL_Id, Master_Unit, Group_Id,Comment_Id,Extended_Info,External_Link,Waste_TN_Id
                       , Timed_TN_Id,Timed_Event_Association,Uses_Start_Time,BOMSPECS)
  SELECT pu.PU_Id
       , PU_Desc
       , Master_order= case When (Master_Unit IS Null) and (PU_Order is NuLL)   Then  pu.PU_Id
                            When (Master_Unit IS Not Null) and (select PU_Order from prod_units where pu_Id = pu.Master_Unit) is Null Then pu.Master_Unit
                            When Master_Unit IS Null  Then PU_Order
                            Else (select convert(Int,PU_Order) from prod_units where pu_Id = pu.Master_Unit) 
                       End 
       , PU_Order, PL_Id, Master_Unit, Group_Id, Comment_Id, Extended_Info, External_Link
       , Waste_TN_Id = pe2.Name_Id,Timed_TN_Id = pe.Name_Id,Timed_Event_Association = Coalesce(pu.Timed_Event_Association,0)
       , Uses_Start_Time = Coalesce(pu.Uses_Start_Time,0),0
    FROM Prod_Units pu
    LEFT JOIN Prod_Events pe  ON  pe.PU_Id = pu.PU_Id AND pe.Event_type = 2    -- Delay (timed)
    LEFT JOIN Prod_Events pe2 ON pe2.PU_Id = pu.PU_Id AND pe2.Event_type = 3   -- Waste 
    WHERE pu.PU_Id > 0 
  Update #ProdUnits Set BOMSPECS = 1 
 	 From #ProdUnits
 	 Join Prod_Units pu on #ProdUnits.pu_Id =  Coalesce(pu.Master_Unit,pu.pu_Id)
        Join Variables v on v.pu_Id = pu.Pu_Id
 	 Join Specifications s on s.spec_Id = v.Spec_Id
 	 Join Product_Properties pp on pp.Prop_Id = s.Prop_Id and  pp.Property_Type_Id = 2
  Select * from #ProdUnits ORDER BY PL_Id,Master_order,Master_Unit,PU_Order
  Drop Table #ProdUnits
*/
  -- ( Portal 3 ) Get production unit records: PU_Id, PU_Desc, PL_Id, Master_Unit
/*
   SELECT pu.PU_Id, PU_Desc, PL_Id, Master_Unit
     FROM Prod_Units pu
    WHERE pu.PU_Id > 0 
*/
  -- ( Portal 4 ) Get production group records.
--  SELECT PUG_Id, PU_Id, PUG_Desc FROM PU_Groups WHERE PUG_Id > 0 ORDER BY PUG_Desc
/*
     SELECT PUG_Id, PU_Id,Group_Id, PUG_Desc, PUG_Order, Comment_Id, External_Link
       FROM PU_Groups
      WHERE PUG_Id > 0
   ORDER BY PUG_Order, PUG_Desc
*/
  -- ( Portal 5 ) Get property records
--  SELECT Prop_Id, Prop_Desc FROM Product_Properties ORDER BY Prop_Desc
/*
  Update Product_Properties set Property_Type_Id = 1 where Property_Type_Id is null
  SELECT Prop_Id, Prop_Desc, Comment_Id, Group_Id, External_Link, Property_Type_Id, Product_Family_Id, Auto_Sync_Chars
    FROM Product_Properties Order By  Prop_Desc
*/
/*
  Create Table #HistorianPW(Hist_Id Int,  Hist_Password  VarChar(255))
  Execute spCmn_GetHistorianPWData2 'EncrYptoR'
  SELECT h.Hist_Id, Hist_Servername = Coalesce(Hist_Servername,''), Hist_Username, hp.Hist_Password, Hist_Default, Hist_OS_Id,Hist_Type_Id,Alias
 	  	 FROM Historians  h
 	 Join #HistorianPW hp on hp.Hist_Id = h.Hist_Id
 	  Order By  Hist_Servername
  Drop table #HistorianPW
*/
  -- Get Displays.
/*
  SELECT Sheet_Type_Id,Sheet_Type_Desc,App_Id  From Sheet_Type st
 	  Where Is_Active = 1
 	  order by Sheet_Type_Desc 
  SELECT Sheet_Group_Id,Sheet_Group_Desc,Group_Id From Sheet_Groups Order By Sheet_Group_Desc
*/
  -- ( Portal 6 ) Get Product_Family_Id, Product_Family_Desc
--  SELECT Product_Family_Id, Product_Family_Desc FROM Product_Family ORDER BY Product_Family_Desc
/*
  Select Product_Family_Id,Product_Family_Desc,External_Link,Comment_Id,Group_Id 
 	 From Product_Family Order By Product_Family_Desc
*/
  -- ( Portal 7 ) Get Product_Grp_Id, Product_Grp_Desc
--  SELECT Product_Grp_Id, Product_Grp_Desc FROM Product_Groups ORDER BY Product_Grp_Desc
  --Select * from Product_Groups  Order By Product_Grp_Desc
/*
  Create Table #CO(Comparison_Operator_Id Int,Comparison_Operator_Value VarChar(25))
  Insert INto #CO (Comparison_Operator_Id,Comparison_Operator_Value)
   	 select Comparison_Operator_Id,Comparison_Operator_Value from Comparison_Operators
  Insert Into #CO (Comparison_Operator_Id,Comparison_Operator_Value) Values (0,'<None>')
  Select * From #CO
  Drop Table #CO
  Select ER_Id,ER_Address,ER_Desc From Email_Recipients order by ER_Desc
  Select EG_Id,EG_Desc from Email_Groups where EG_Id <> 50 order by EG_Desc
  Select EG_Id,ER_Id,EGR_Id From Email_Groups_Data
  Select ERC_Id,ERC_Desc,[System] = case When ERC_Id < 100 Then 1 Else 0 End
 From Event_Reason_Catagories Where ERC_Id <> 100 order by ERC_Desc
*/
-- ( Portal 8 ) Get ALL variables
/*
  SELECT Var_Id, Var_Desc, PU_Id, PUG_Id, PVar_Id, Eng_Units
    FROM Variables
   WHERE PU_Id <> 0
ORDER BY Var_Desc
*/
