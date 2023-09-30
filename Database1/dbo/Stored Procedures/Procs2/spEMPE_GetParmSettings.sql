Create Procedure dbo.spEMPE_GetParmSettings
@mode int,
@UID int,
@User_ID int
AS
-- spEMPE_GetParmSettings 1,1,1 
Create Table #Conf (ID int, Conf_Desc nvarchar(20))
  Insert Into #Conf(ID,Conf_Desc) Values(6,'Cross')
  Insert Into #Conf(ID,Conf_Desc) Values(7,'Diagonal Cross')
  Insert Into #Conf(ID,Conf_Desc) Values(5,'Downward Diagonal')
  Insert Into #Conf(ID,Conf_Desc) Values(2,'Horizontal')
  Insert Into #Conf(ID,Conf_Desc) Values(1,'Transparent')
  Insert Into #Conf(ID,Conf_Desc) Values(4,'Upward Diagonal')
  Insert Into #Conf(ID,Conf_Desc) Values(3,'Vertical')
Declare @HaveData Int,
 	  	 @TimeZone 	 nVarChar(100)
 	  	 
SET @HaveData = 0
if @mode = 1
BEGIN
 	 IF Exists(SELECT * From Tests)
 	  	 SET @HaveData = 1
 	 IF Exists(SELECT * From Events)
 	  	 SET @HaveData = 1
 	 IF Exists(SELECT * From Timed_Event_Details)
 	  	 SET @HaveData = 1
 	 IF Exists(SELECT * From Waste_Event_Details)
 	  	 SET @HaveData = 1
 	 SELECT @TimeZone = Value FROM Site_Parameters WHERE Parm_Id = 192
 	 IF Not Exists(SELECT 1 FROM TimeZoneTranslations WHERE TimeZone = @TimeZone)
 	  	 SELECT @HaveData = 0
    select pc.Parameter_Category_Desc, p.Parm_Name, p.Parm_Long_Desc, sp.HostName, p.IsEncrypted, p.Parm_ID, p.Field_Type_Id, sp.Value, p.Add_Delete,
           p.Parm_Min, p.Parm_Max, sp.Parm_Required,
           Value_Text = 
        CASE When  Field_Type_Id = 22 and sp.Value = '1' Then 'TRUE'
 	  	  	 When  Field_Type_Id = 22 and sp.Value = '0' Then 'FALSE'
 	  	  	 When  Field_Type_Id = 8 Then (Select ST_Desc From Sampling_Type Where ST_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 9 Then (Select Pu_Desc From Prod_Units Where pu_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 10 Then (Select Var_Desc From Variables Where Var_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 13 Then (Select WET_Name From Waste_Event_Type Where WET_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 14 Then (Select WEMT_Name From Waste_Event_Meas Where WEMT_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 15 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 16 Then (Select ProdStatus_Desc From Production_Status Where ProdStatus_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 23 Then (Select Char_Desc From Characteristics Where Char_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 24 Then (Select CS_Desc From Color_Scheme Where CS_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 29 Then (Select Tree_Statistic_Desc From Tree_Statistics Where Tree_Statistic_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 30 Then (Select AL_Desc From Access_Level Where Al_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 31 Then (Select Conf_Desc From #Conf Where Id = sp.Value)
 	  	  	 When  Field_Type_Id = 33 Then (Select Sheet_Desc From Sheets where Sheet_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 34 Then (Select Color_Desc From Colors Where Color_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 39 Then (Select Tree_Name From Event_Reason_Tree Where Tree_Name_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 40 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 50 Then (Select ET_Desc from Event_Types Where ET_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 53 Then (Select Language_Desc from Languages Where Language_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 57 Then (Select EG_Desc from Email_Groups Where EG_Id = sp.Value)
 	  	  	 When  Field_Type_Id = 75 Then (Select Testing_Status_Desc from Test_Status  Where Testing_Status = sp.Value)
 	  	  	 When Field_Type_Id IN( 28 ,31,38,41,42,43,44,45,46,47,48 ,49,55,56 ,64,65,70,74) Then 
                    (Select Field_Desc From ED_FieldType_ValidValues Where ED_Field_Type_Id = Field_Type_Id and Field_Id = sp.Value)
             Else  sp.Value End,
           ft.sp_Lookup, ft.Store_Id, Is_Esignature = Coalesce(p.Is_Esignature, 0),[RunTimeData] = @HaveData
    from Site_Parameters sp
    join Parameters p on p.Parm_ID = sp.Parm_ID
    Left Join Ed_FieldTypes ft on ft.Ed_Field_Type_Id = p.Field_Type_Id
    Left Join Parameter_Categories pc On pc.Parameter_Category_Id = p.Parameter_Category_Id
    Where p.System <> 1
    order by pc.Parameter_Category_Desc,p.Parm_Name
END
if @mode = 2
BEGIN
    Create table #User_Parms (Parameter_Category_Desc nvarchar(255), User_Name nvarchar (30), User_ID int, Parm_Name nvarchar (50), Parm_Long_Desc nvarchar(255),
     	  	  	  	  	  Parm_ID int, HostName nvarchar (30), value varchar(5000), IsEncrypted int,
     	  	  	  	  	  Field_Type_Id int,Value_Text varchar(5000), Sp_Lookup tinyint, Store_Id tinyint, Add_Delete tinyint, Parm_Min int, Parm_Max int, Parm_Required bit, Is_Esignature tinyint)
    Insert into #user_Parms (Parameter_Category_Desc, User_ID, Parm_ID, HostName, Value,Field_Type_Id, Value_Text, Sp_Lookup, Store_Id, Add_Delete, Parm_Min, Parm_Max, Parm_Required, Is_Esignature)
      select pc.Parameter_Category_Desc, up.User_ID, up.Parm_ID, up.HostName, up.Value, p.Field_Type_Id,
             Value_Text = CASE When Field_Type_Id = 22 and up.Value = '1' Then 'TRUE'
               When  Field_Type_Id = 22 and up.Value = '0' Then 'FALSE'
               When  Field_Type_Id = 8 Then (Select ST_Desc From Sampling_Type Where ST_Id = up.Value)
               When  Field_Type_Id = 9 Then (Select Pu_Desc From Prod_Units Where pu_Id = up.Value)
               When  Field_Type_Id = 10 Then (Select Var_Desc From Variables Where Var_Id = up.Value)
               When  Field_Type_Id = 13 Then (Select WET_Name From Waste_Event_Type Where WET_Id = up.Value)
               When  Field_Type_Id = 14 Then (Select WEMT_Name From Waste_Event_Meas Where WEMT_Id = up.Value)
               When  Field_Type_Id = 15 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = up.Value)
               When  Field_Type_Id = 16 Then (Select ProdStatus_Desc From Production_Status Where ProdStatus_Id = up.Value)
               When  Field_Type_Id = 23 Then (Select Char_Desc From Characteristics Where Char_Id = up.Value)
               When  Field_Type_Id = 24 Then (Select CS_Desc From Color_Scheme Where CS_Id = up.Value)
               When  Field_Type_Id = 29 Then (Select Tree_Statistic_Desc From Tree_Statistics Where Tree_Statistic_Id = up.Value)
               When  Field_Type_Id = 30 Then (Select AL_Desc From Access_Level Where Al_Id = up.Value)
               When  Field_Type_Id = 31 Then (Select Conf_Desc From #Conf Where Id = up.Value)
        	        When  Field_Type_Id = 33 Then (Select Sheet_Desc From Sheets where Sheet_Id = up.Value)
          	      When  Field_Type_Id = 34 Then (Select Color_Desc From Colors Where Color_Id = up.Value)
          	      When  Field_Type_Id = 39 Then (Select Tree_Name From Event_Reason_Tree Where Tree_Name_Id = up.Value)
         	      When  Field_Type_Id = 40 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = up.Value)
           	  	  When  Field_Type_Id = 50 Then (Select ET_Desc from Event_Types Where ET_Id = up.Value)
           	  	  When  Field_Type_Id = 53 Then (Select Language_Desc from Languages Where Language_Id = up.Value)
           	  	  When  Field_Type_Id = 57 Then (Select EG_Desc from Email_Groups Where EG_Id = up.Value)
               When Field_Type_Id = 28 or Field_Type_Id = 31 or Field_Type_Id = 38 or 
                    Field_Type_Id = 41 or Field_Type_Id = 42 or Field_Type_Id = 43 or Field_Type_Id = 44 or 
                    Field_Type_Id = 45 or Field_Type_Id = 46 or Field_Type_Id = 47 or Field_Type_Id = 48 or 
                    Field_Type_Id = 49 or Field_Type_Id = 55 or Field_Type_Id = 56 Then
                      (Select Field_Desc From ED_FieldType_ValidValues Where ED_Field_Type_Id = Field_Type_Id and Field_Id = up.Value)
               Else up.Value End,
             ft.sp_Lookup, ft.Store_Id, p.Add_Delete,
             p.Parm_Min, p.Parm_Max, up.Parm_Required, Coalesce(p.Is_Esignature, 0)
      from User_Parameters up
      left Join  Parameters p on p.Parm_Id = up.Parm_Id
      Left Join Ed_FieldTypes ft on ft.Ed_Field_Type_Id = p.Field_Type_Id
      Left Join Parameter_Categories pc On pc.Parameter_Category_Id = p.Parameter_Category_Id
      where User_Id = @UID and  p.System <> 1
    update #User_Parms
    set #User_Parms.User_Name = u.username from #User_Parms
    left outer join Users u on #User_Parms.User_ID = u.user_ID
    update #User_Parms
    set #User_Parms.Parm_Name = p.Parm_Name, #User_Parms.Parm_Long_Desc = p.Parm_Long_Desc from #User_Parms
    left outer join Parameters p on #User_Parms.Parm_ID = p.parm_ID
    update #User_Parms
    set #User_Parms.IsEncrypted = t.IsEncrypted from #User_Parms
    left outer join Parameters t on #User_Parms.Parm_ID = t.parm_ID
    select Parameter_Category_Desc , [User_Name], [User_ID], Parm_Name, Parm_Long_Desc,
     	  	  	  	  	  Parm_ID , HostName, [value], IsEncrypted,Field_Type_Id ,Value_Text , Sp_Lookup, 
 	  	  	  	  	  	 Store_Id , Add_Delete , Parm_Min , Parm_Max , Parm_Required , Is_Esignature,[RunTimeData] = 1 
 	 from #User_Parms
    order by Parameter_Category_Desc,Parm_Name
    drop table #User_Parms
END
if @mode = 3
BEGIN
 	 SELECT [RunTimeData] = @HaveData
    select p.Parm_Name, p.Parm_Long_Desc, p.IsEncrypted, p.Parm_ID, p.Field_Type_Id, sp.Value, p.Add_Delete,
           p.Parm_Min, p.Parm_Max, sp.Parm_Required,
           Value_Text = 
        CASE When  Field_Type_Id = 22 and sp.Value = '1' Then 'TRUE'
 	  	  	  	 When  Field_Type_Id = 22 and sp.Value = '0' Then 'FALSE'
 	  	  	  	 When  Field_Type_Id = 8 Then (Select ST_Desc From Sampling_Type Where ST_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 9 Then (Select Pu_Desc From Prod_Units Where pu_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 10 Then (Select Var_Desc From Variables Where Var_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 13 Then (Select WET_Name From Waste_Event_Type Where WET_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 14 Then (Select WEMT_Name From Waste_Event_Meas Where WEMT_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 15 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 16 Then (Select ProdStatus_Desc From Production_Status Where ProdStatus_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 23 Then (Select Char_Desc From Characteristics Where Char_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 24 Then (Select CS_Desc From Color_Scheme Where CS_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 29 Then (Select Tree_Statistic_Desc From Tree_Statistics Where Tree_Statistic_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 30 Then (Select AL_Desc From Access_Level Where Al_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 31 Then (Select Conf_Desc From #Conf Where Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 33 Then (Select Sheet_Desc From Sheets where Sheet_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 34 Then (Select Color_Desc From Colors Where Color_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 39 Then (Select Tree_Name From Event_Reason_Tree Where Tree_Name_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 40 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 50 Then (Select ET_Desc from Event_Types Where ET_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 53 Then (Select Language_Desc from Languages Where Language_Id = sp.Value)
 	  	  	  	 When  Field_Type_Id = 57 Then (Select EG_Desc from Email_Groups Where EG_Id = sp.Value)
 	  	  	  	 When Field_Type_Id In( 28 , 31 ,38,41 ,42,43 ,44,45 ,46,47,48,49 ,55 ,56,64,65) Then 
                    (Select Field_Desc From ED_FieldType_ValidValues Where ED_Field_Type_Id = Field_Type_Id and Field_Id = sp.Value)
             Else  sp.Value End,
           ft.sp_Lookup, ft.Store_Id, Is_Esignature = Coalesce(p.Is_Esignature, 0)
    from Dept_Parameters sp
    join Parameters p on p.Parm_ID = sp.Parm_ID
    Left Join Ed_FieldTypes ft on ft.Ed_Field_Type_Id = p.Field_Type_Id
    Where p.System <> 1 and sp.Dept_Id = @UID
    order by p.Parm_Name
END
--drop table #temp
drop table #conf
