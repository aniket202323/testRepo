CREATE Procedure dbo.spEMEPC_OtherProductPaths
@Path_Id int,
@PU_Id int,
@Prod_Id int,
@User_Id int,
@Message varchar(7000) output
AS
Declare @PU_Desc nvarchar(50), 
@@Path_Code nvarchar(50),
@@Path_Id int,
@Paths varchar(6745),
@StaticMessage nvarchar(255)
Select @PU_Desc = PU_Desc
From Prod_Units
Where PU_Id = @PU_Id
Select @StaticMessage =  @PU_Desc + ' is also the scheduling Unit on the following Paths.  You must manually move the products for each of the following paths: ' + Char(13)
Declare PathsCursor INSENSITIVE CURSOR For 
  Select Distinct pep.Path_Code, pep.Path_Id
  From PrdExec_Paths pep
 	 Join PrdExec_Path_Units pepu on pepu.Path_Id = pep.Path_Id
 	 Where pep.Path_Id <> @Path_Id
 	 And pepu.PU_Id = @PU_Id
 	 And PEPU.Is_Schedule_Point = 1
 	 Order By pep.Path_Code ASC
  For Read Only
  Open PathsCursor  
MyPathsLoop:
  Fetch Next From PathsCursor Into @@Path_Code, @@Path_Id
  If (@@Fetch_Status = 0)
    Begin
select @@Path_Code as Path_Code
 	  	  	 If @Paths is NULL
 	  	  	  	 Begin
 	  	  	  	  	 If (Select Count(*) From PrdExec_Path_Products Where Path_Id = @@Path_Id and Prod_Id = @Prod_Id) = 0
 	  	  	  	  	  	 Select @Paths = @@Path_Code
 	  	  	  	 End
 	  	  	 Else
 	  	  	  	 Begin
 	  	  	  	  	 If (Select Count(*) From PrdExec_Path_Products Where Path_Id = @@Path_Id and Prod_Id = @Prod_Id) = 0
 	  	  	  	  	  	 Select @Paths = @Paths  + Case When Len(@Paths + ', ' + @@Path_Code) <= 6745 Then Char(13) + @@Path_Code Else '' End
 	  	  	  	 End
      Goto MyPathsLoop
    End
Close PathsCursor
Deallocate PathsCursor
Select @Message = @StaticMessage + @Paths
