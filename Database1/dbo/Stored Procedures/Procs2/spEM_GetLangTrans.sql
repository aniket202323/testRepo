CREATE PROCEDURE dbo.spEM_GetLangTrans
@Language_Id int,
@User_Id int,
@App_Id int = NULL,
@Min_Prompt int = NULL,
@Max_Prompt int = NULL,
@Prompt_String VarChar(8000) = Null,
@Override_Prompt VarChar(8000) = Null
AS
Declare @App_Min_Prompt int
Declare @App_Max_Prompt int
--Determine the prompt range for the specified language
Select @App_Min_Prompt = Min_Prompt, @App_Max_Prompt = Max_Prompt From AppVersions Where App_Id = @App_Id
Select ld1.Prompt_Number,
 	 Langs.Language_Id Lang_Id, Langs.Language_Desc Lang_Name,
 	 coalesce(ld3.Prompt_String,ld1.Prompt_String) as Prompt_String, ld2.Prompt_String as Prompt_Override
From Language_Data ld1 --English prompts
Left Outer Join Language_Data ld3 on ld3.Prompt_Number = ld1.Prompt_Number and (@Language_Id Is Null Or ld3.Language_id = @Language_Id) --Join to get the prompt for the users language
Left Outer Join Language_Data ld2 on ld2.Prompt_Number = ld1.Prompt_Number and ld2.Language_id = 0 - ld3.Language_Id - 1 --Join the right override language
Join Languages langs On (langs.Language_Id = Case When ld3.Prompt_String Is Null Then 0 Else ld3.Language_Id End)
Where ld1.Language_Id = 0
And (@App_Min_Prompt Is Null Or ld1.Prompt_Number >= @App_Min_Prompt)
And (@App_Max_Prompt Is Null Or ld1.Prompt_Number <= @App_Max_Prompt)
And (@Min_Prompt Is Null Or ld1.Prompt_Number >= @Min_Prompt)
And (@Max_Prompt Is Null Or ld1.Prompt_Number <= @Max_Prompt)
And (@Prompt_String Is Null Or ld3.Prompt_String Like '%' + @Prompt_String + '%')
And (@Override_Prompt Is Null Or ld2.Prompt_String Like '%' + @Override_Prompt + '%')
order by ld1.Prompt_Number, langs.Language_Id
