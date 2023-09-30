CREATE procedure [dbo].[spASP_wrGetTranslations]
@CurrPrompt int,
@LanguageId int
AS
DECLARE @PromptMin int
DECLARE @PromptMax int
SELECT 
 	 @PromptMin = CASE
 	  WHEN @CurrPrompt - 100 > 0 THEN @CurrPrompt - 100
 	  ELSE 1
        END, 
 	 @PromptMax = @CurrPrompt + 100 
Select Distinct p.Prompt_Number, p.Prompt_String, @PromptMin [Min], @PromptMax [Max]
From Language_Data p
Where p.Prompt_Number >= @PromptMin and p.Prompt_Number <= @PromptMax
  and p.language_Id = @LanguageId
order by p.Prompt_Number
/* --- NEED to ignore the override here, handle in WebApps Code
If @IgnoreLocalPrompts = 'False'
--Substitute system message prompts with the Local message prompts
 BEGIN
    Select p.Prompt_Number, case
           When p2.Prompt_String is not Null then p2.Prompt_String
           Else p.Prompt_String End as Prompt_String
 	    , @PromptMin [Min], @PromptMax [Max]
    From Language_Data p
    Left Outer Join Language_Data p2 on p2.Prompt_Number = p.Prompt_Number and p2.Language_Id = -1
    Where p.Prompt_Number >= @PromptMin and p.Prompt_Number <= @PromptMax
      and p.language_Id = @LanguageId order by p.Prompt_Number
 END
Else
--Ignore any Local message prompts
 BEGIN
  Select Distinct p.Prompt_Number, p.Prompt_String
   , @PromptMin [Min], @PromptMax [Max]
   From Language_Data p
   Where p.Prompt_Number >= @PromptMin and p.Prompt_Number <= @PromptMax
     and p.language_Id = @LanguageId
      order by p.Prompt_Number
 END
*/
