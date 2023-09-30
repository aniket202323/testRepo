CREATE PROCEDURE dbo.spRS_GetVariables
@TimeBased int = Null,
@PuId int = Null,
@Str varchar(8000) = Null
 AS
Declare @SQLStr varchar(8000)
Begin
 	 If @TimeBased Is Null
 	  	 Begin
 	  	  	 If @PuId is null
 	  	        	 Begin
 	  	          	  	 Select @SQLStr = 'Select Var_Id, Var_Desc, Event_Type From Variables '
 	  	          	  	 If @Str Is Not Null
 	  	          	  	   Select @SQLStr = @SQLStr + ' where var_Id not in (' + @Str + ')'
 	  	          	  	 
 	  	          	  	 Select @SQLStr = @SQLStr + ' Order By Var_Desc'
 	  	        	 End
 	  	     Else
 	  	        	 Begin
 	  	        	  	 Select @SQLStr = 'Select Var_Id, Var_Desc, Event_Type From Variables Where PU_Id = @PuId'
 	  	        	  	 If @Str Is Not Null
 	  	          	  	   Select @SQLStr = @SQLStr + ' and var_Id not in (' + @Str + ')'
 	  	          	  	  Select @SQLStr = @SQLStr + ' Order By Var_Desc'
 	  	          	  	  Select @SQLStr = Replace(@SQLStr, '@PUID', @PuId)
 	  	        	 End
 	  	       
 	  	       Exec(@SQLStr)
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 If @TimeBased = 0 -- Time Base Variables and also Time/Product Variables
 	  	    	  	 Begin
 	  	      	  	  	 If @PuId is null
 	  	  	  	   	  	 Begin
 	  	  	  	     	  	  	 Select @SQLStr = 'Select Var_Id, Var_Desc, Event_Type From Variables Where Event_Type = 0 Or Event_Type = 5 '
 	  	  	  	   	  	  	 If @Str Is Not Null
 	  	  	  	     	  	  	   Select @SQLStr = @SQLStr + ' and var_Id not in (' + @Str + ')'
 	  	  	  	     	  	  	  Select @SQLStr = @SQLStr + ' Order By Var_Desc'
 	  	  	  	   	  	 End
 	  	      	  	  	 Else
 	  	  	  	   	  	 Begin
 	  	  	  	     	  	  	 Select @SQLStr = 'Select Var_Id, Var_Desc, Event_Type From Variables Where PU_Id = @PuId And (Event_Type = 0  Or Event_Type = 5) '
 	  	  	  	   	  	  	 If @Str Is Not Null
 	  	  	  	     	  	  	   Select @SQLStr = @SQLStr + ' and var_Id not in (' + @Str + ')'
 	  	  	  	     	  	  	  Select @SQLStr = @SQLStr + ' Order By Var_Desc'
 	  	  	  	   	  	 End
 	  	  	  	   	 Select @SQLStr = Replace(@SQLStr, '@PUID', @PuId)
 	  	  	  	   	 Exec(@SQLStr)
 	  	    	  	 End
 	  	  	 Else If @TimeBased = 1  -- Event Based
 	  	  	 Begin
 	  	  	  	 If @PuId is null
 	  	        	  	 Begin
 	  	          	  	  	 Select @SQLStr = 'Select Var_Id, Var_Desc, Event_Type From Variables Where Event_Type in (1,14) '
 	  	  	  	   	  	 If @Str Is Not Null
 	  	  	  	     	  	   Select @SQLStr = @SQLStr + ' and var_Id not in (' + @Str + ')'
 	  	  	  	     	  	  Select @SQLStr = @SQLStr + ' Order By Var_Desc'
 	  	        	  	 End
 	  	      	  	 Else
 	  	        	  	 Begin
 	  	          	  	  	 Select @SQLStr = 'Select Var_Id, Var_Desc, Event_Type From Variables Where Event_Type in (1,14) And PU_Id = @PuId '
 	  	  	  	   	  	 If @Str Is Not Null
 	  	  	  	     	  	   Select @SQLStr = @SQLStr + ' and var_Id not in (' + @Str + ')'
 	  	  	  	     	  	  Select @SQLStr = @SQLStr + ' Order By Var_Desc'
 	  	        	  	 End
 	  	        	 Select @SQLStr = Replace(@SQLStr, '@PUID', @PuId)
 	  	        	 Exec(@SQLStr)
 	  	  	 End
 	  	  	 Else  If @TimeBased = 2
 	  	  	 Begin
 	  	  	  	 If @PuId is null
 	  	        	  	 Begin
 	  	          	  	  	 Select Var_Id, Var_Desc, Event_Type,extended_info
 	  	          	  	  	 From Variables
 	  	          	  	  	 Where Extended_Info like '%WB/2%'
 	  	          	  	  	 Order By Var_Desc
 	  	        	  	 End
 	  	      	  	 Else
 	  	        	  	 Begin
 	  	          	  	  	 Select Var_Id, Var_Desc, Event_Type,extended_info
 	  	  	  	  	  	 From Variables
 	  	          	  	  	 Where Extended_Info like '%WB/2%' and PU_Id = @PuId
 	  	          	  	  	 Order By Var_Desc
 	  	        	  	 End
 	  	  	 End 	 
 	  	  	 Else  If @TimeBased = 3
 	  	  	 Begin
 	  	  	  	 If @PuId is null
 	  	        	  	 Begin
 	  	          	  	  	 Select Var_Id, Var_Desc, Event_Type,extended_info
 	  	          	  	  	 From Variables
 	  	          	  	  	 Where Extended_Info like '%WB/3%'
 	  	          	  	  	 Order By Var_Desc
 	  	        	  	 End
 	  	      	  	 Else
 	  	        	  	 Begin
 	  	          	  	  	 Select Var_Id, Var_Desc, Event_Type,extended_info
 	  	  	  	  	  	 From Variables
 	  	          	  	  	 Where Extended_Info like '%WB/3%' and PU_Id = @PuId
 	  	          	  	  	 Order By Var_Desc
 	  	        	  	 End
 	  	  	 End 	 
 	  	  	 Else  If @TimeBased = 4
 	  	  	 Begin
 	  	  	  	 If @PuId is null
 	  	        	  	 Begin
 	  	          	  	  	 Select Var_Id, Var_Desc, Event_Type,extended_info
 	  	          	  	  	 From Variables
 	  	          	  	  	 Where Extended_Info like '%WB/4%'
 	  	          	  	  	 Order By Var_Desc
 	  	        	  	 End
 	  	      	  	 Else
 	  	        	  	 Begin
 	  	          	  	  	 Select Var_Id, Var_Desc, Event_Type,extended_info
 	  	  	  	  	  	 From Variables
 	  	          	  	  	 Where Extended_Info like '%WB/4%' and PU_Id = @PuId
 	  	          	  	  	 Order By Var_Desc
 	  	        	  	 End
 	  	  	 End 	 
 	  	  	 Else
 	  	  	 Begin
 	  	  	  	 If @PuId is null
 	  	       	  	 Begin
 	  	          	  	  	 Select Var_Id, Var_Desc, Event_Type
 	  	          	  	  	 From Variables
 	  	          	  	  	 Order By Var_Desc
 	  	        	  	 End
 	  	      	  	 Else
 	  	  	        	 Begin
 	  	  	  	     	  	 Select Var_Id, Var_Desc, Event_Type
 	  	          	  	  	 From Variables
 	  	          	  	  	 Where PU_Id = @PuId
 	  	          	  	  	 Order By Var_Desc
 	  	        	  	 End
 	  	  	 End
 	  	 End
 	 End
