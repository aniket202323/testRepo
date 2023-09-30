CREATE PROCEDURE [dbo].[spServer_WtrGetVars]     
AS
Declare
  @DefaultHistorian nVarChar(100),
  @@VarId int,
  @@DSId int,
  @Result nVarChar(25),
  @Result_On datetime
Select @DefaultHistorian = NULL
Select @DefaultHistorian = COALESCE(Alias,Hist_Servername) From Historians Where Hist_Default = 1
If (@DefaultHistorian Is NULL)
  Select @DefaultHistorian = ''
Select VarId = Var_Id,
       DataType = Data_Type_Id,
       ActualOutputTag = Output_Tag,
       TagOnly = 
        CASE CharIndex('\\',Output_Tag)
          When 0 Then Output_Tag
          When 1 Then SubString(Output_Tag,CharIndex('\',SubString(Output_Tag,3,100)) + 3,100)
          Else
            Output_Tag
        END,
       NodeName = 
        CASE CharIndex('\\',Output_Tag)
          When 0 Then @DefaultHistorian
          When 1 Then SubString(Output_Tag,3,CharIndex('\',SubString(Output_Tag,3,100)) - 1)
          Else
            @DefaultHistorian
        END,
       Var_Precision
  From Variables_Base 
  Where (Output_Tag Is Not NULL) And (Is_Active = 1) 
 	  	  	 And (PU_Id > 0) And -- Added by Tom Nettell 5/4/2011 this will exclude unitless variables
 	  	     ((CharIndex('\\',Output_Tag) = 0) or 
 	  	  	  	  ((CharIndex('\\',Output_Tag) = 1) and (Len(Output_Tag) > 2) and (CharIndex('\',SubString(Output_Tag,3,100)) > 0)) or 
 	  	  	  	  ((CharIndex('\\',Output_Tag) > 0) and (Len(Output_Tag) > 2))) and 
 	  	  	  	 ((Write_Group_DS_Id < 50000) or (Write_Group_DS_Id is Null))
  Order by NodeName,TagOnly
