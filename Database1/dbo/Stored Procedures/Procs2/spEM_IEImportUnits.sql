CREATE PROCEDURE dbo.spEM_IEImportUnits
@Dept_Desc 	  	  	 nVarChar(100),
@PL_Desc 	  	  	 nVarChar(100),
@PU_Desc 	  	  	 nVarChar(100),
@Master_Unit_Desc 	 nVarChar(100),
@External_Link 	  	 nvarchar(255),
@Group_Desc 	  	  	 nVarChar(100),
@Extended_Info 	  	 nvarchar(255),
@UseStartTime 	  	 nVarChar(10),
@User_Id 	  	  	 Int
AS
Declare @New_Master  	 int,
 	 @Master_Unit 	 int,
 	 @Description 	 nVarChar(100),
 	 @PL_Id 	  	 int,
 	 @Dept_Id 	  	 int,
 	 @Group_Id 	 int,
 	 @PU_Id 	  	 Int,
 	 @IStartT 	 Int
/* Initialize */
Select  	 @Master_Unit = Null,@PL_Id = Null,@PU_Id = Null
/* Clean Arguments */
Select @Extended_Info = LTrim(RTrim(@Extended_Info))
Select @External_Link = LTrim(RTrim(@External_Link))
Select @Dept_Desc = RTrim(LTrim(@Dept_Desc))
Select @PL_Desc = RTrim(LTrim(@PL_Desc))
Select @PU_Desc = RTrim(LTrim(@PU_Desc))
Select @Master_Unit_Desc =  RTrim(LTrim(@Master_Unit_Desc))
Select @Group_Desc = RTrim(LTrim(@Group_Desc))
If  @Dept_Desc = '' or @Dept_Desc IS NULL
BEGIN
 	 Select  'Department Not Found'
 	 Return(-100)
END
If  @PL_Desc = '' or @PL_Desc IS NULL
BEGIN
 	 Select  'Production Line Not Found'
 	 Return(-100)
END
If @PU_Desc = '' or @PU_Desc IS NULL 
BEGIN
 	 Select  'Production Unit Not Found'
 	 Return(-100)
END
If @UseStartTime = '1' 
 	 Select @IStartT = 1
Else
 	 Select @IStartT = 0
Select @Dept_Id = Dept_Id From Departments
 Where Dept_Desc = @Dept_Desc
If @Dept_Id Is Null
Begin
 	 Execute spEM_CreateDepartment @Dept_Desc,@User_Id,@Dept_Id Output
 	 If @Dept_Id IS NULL
  BEGIN
 	  	 Select 'Failed - Error Creating Department'
 	  	 Return(-100)
  END
End
Select @PL_Id = PL_Id
 	 From Prod_Lines
 	 Where PL_Desc = @PL_Desc
If @PL_Id Is Null
Begin
 	 Execute spEM_CreateProdLine @PL_Desc,@Dept_Id,@User_Id,@PL_Id Output
End
If @PL_Id IS NULL
BEGIN
 	 Select 'Failed - Error Creating Line'
 	 Return(-100)
END
If @Master_Unit_Desc <> '' and @Master_Unit_Desc is not null
BEGIN
 	 Select @Master_Unit = PU_Id
 	  	 From Prod_Units
 	  	 Where PU_Desc = @Master_Unit_Desc And PL_Id = @PL_Id
 	 If @Master_Unit Is Null 
 	 BEGIN
 	  	 Execute spEM_CreateProdUnit @Master_Unit_Desc,@PL_Id,@User_Id,@Master_Unit Output
 	  	 If @Master_Unit Is Null 
 	  	 BEGIN
 	  	  	 Select 'Failed - Master Unit not found'
 	  	  	 Return (-100)
 	  	 END
 	 END
END 	  
Select @PU_Id = Null
Select @PU_Id = PU_Id from Prod_Units 
 	 Where PU_Desc = @PU_Desc 
 	   and PL_Id = @PL_Id
If @PU_Id IS NULL 
  Begin
 	 Execute spEM_CreateProdUnit @PU_Desc,@PL_Id,@User_Id,@PU_Id Output
  End
If @PU_Id IS NULL
BEGIN
 	 Select 'Failed - Error Creating Unit'
 	 Return(-100)
END
If @Master_Unit is not null
BEGIN
 	 SELECT @New_Master = Coalesce(Master_Unit,PU_Id) FROM Prod_Units WHERE PU_Id = @Master_Unit
 	 Execute spEM_SetMasterUnit  @PU_Id,@New_Master, @User_Id
End 	  
 /************************************************************************************/
 /* Update group security 	  	  	  	  	            */
 /************************************************************************************/
If @Group_Desc <> '' and @Group_Desc is not null
Begin
 	 Select @Group_Id = Group_Id From Security_Groups
 	  	 Where Group_Desc = @Group_Desc
 	 If @Group_Id Is Not Null
 	  	 Execute spEM_PutSecurityUnit @PU_Id,@Group_Id,@User_Id
 	 Else 
 	 Begin
 	  	 Select 'Failed - Can not find security group'
 	  	 Return (-100)
   End
End
/************************************************************************************/
/* Update external link 	  	  	  	  	            */
/************************************************************************************/
Select 	 @Extended_Info = IsNull(@Extended_Info,Extended_Info),
 	  	  	  	 @External_Link = IsNull(@External_Link,External_Link)
From Prod_Units
Where PU_Id = @PU_Id
Execute spEM_PutExtLink  @PU_Id,'ae',@External_Link,@Extended_Info,@IStartT,@User_Id
