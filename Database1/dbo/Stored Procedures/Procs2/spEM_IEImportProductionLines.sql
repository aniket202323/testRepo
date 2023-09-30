CREATE PROCEDURE dbo.spEM_IEImportProductionLines
@Dept_Desc 	  	 nVarChar(100),
@PL_Desc 	  	 nVarChar(100),
@External_Link 	 nvarchar(255),
@Extended_Info 	 nvarchar(255),
@Group_Desc 	  	 nVarChar(100),
@User_Id 	  	 Int
AS
Declare @Group_Id 	 int,@PL_Id Int,@Dept_Id Int
/* Initialize */
Select  	 @PL_Id = Null,@Dept_Id = Null
/* Clean and verify arguments */
Select  	 @Dept_Desc 	  	 = ltrim(rtrim(@Dept_Desc)),
 	 @PL_Desc 	  	 = ltrim(rtrim(@PL_Desc)),
 	 @Group_Desc 	  	 = ltrim(rtrim(@Group_Desc)),
 	 @Extended_Info  	 = ltrim(rtrim(@Extended_Info)),
 	 @External_Link 	  	 = ltrim(rtrim(@External_Link))
If @Dept_Desc Is Null Or @Dept_Desc = ''
  Begin
 	 Select 'Failed - Department Missing'
    Return (-100)
  End
If @PL_Desc Is Null Or @PL_Desc = ''
  Begin
 	 Select 'Failed - Production Line Missing'
    Return (-100)
  End
/* Get configuration ids */
If @Group_Desc Is Not Null And @Group_Desc <> ''
  Begin
     Select @Group_Id = Group_Id
     From Security_Groups
     Where Group_Desc = @Group_Desc
     If @Group_Id Is Null
 	   Begin
 	  	 Select 'Failed - Security Group not Found'
 	     Return (-100)
  	   End
   End
/* Create Department */
Select @Dept_Id = Dept_Id
From Departments
Where Dept_Desc = @Dept_Desc
If @Dept_Id Is Null
  Begin
 	 Execute spEM_CreateDepartment  @Dept_Desc,@User_Id,@Dept_Id OUTPUT
    If @Dept_Id Is Null
   	   Begin
 	  	 Select 'Failed - Could not create Department'
     	 Return (-100)
   	   End
   End
/* Create line */
Select @PL_Id = PL_Id
From Prod_Lines
Where PL_Desc = @PL_Desc
If @PL_Id Is Null
  Begin
 	 Execute spEM_CreateProdLine  @PL_Desc,@Dept_Id,@User_Id,@PL_Id OUTPUT
    If @PL_Id Is Null
   	   Begin
 	  	 Select 'Failed - Could not create Production Line'
     	 Return (-100)
   	   End
 	 If @Group_Id is not null
 	  	 Execute spEM_PutSecurityLine @PL_Id,@Group_Id,@User_Id
 	 If @Extended_Info <> '' or @Extended_Info is not null or @External_Link <> '' or @External_Link is not null
 	  	 Execute spEM_PutExtLink  @PL_Id, 'ad',@External_Link,@Extended_Info, 0,@User_Id
   End
Else
  Begin
 	 If @Group_Id is not null
 	  	 Execute spEM_PutSecurityLine @PL_Id,@Group_Id,@User_Id
 	 If @Extended_Info <> '' or @Extended_Info is not null or @External_Link <> '' or @External_Link is not null
 	  	 Execute spEM_PutExtLink  @PL_Id, 'ad',@External_Link,@Extended_Info, 0,@User_Id
  End
