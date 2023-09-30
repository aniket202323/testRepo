CREATE TABLE [dbo].[Report_Relative_Dates] (
    [RRD_Id]              INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Date_Prompt_Number]  INT            NULL,
    [Date_Type_Id]        INT            NOT NULL,
    [Default_Prompt_Desc] VARCHAR (100)  NOT NULL,
    [End_Date_SQL]        VARCHAR (1000) NULL,
    [Start_Date_SQL]      VARCHAR (1000) NULL,
    CONSTRAINT [Report_Relative_Dates_PK_Id] PRIMARY KEY CLUSTERED ([RRD_Id] ASC),
    CONSTRAINT [RepRelDates_FK_RepRelDateTypes] FOREIGN KEY ([Date_Type_Id]) REFERENCES [dbo].[Report_Relative_Date_Types] ([Date_Type_Id]),
    CONSTRAINT [Report_Relative_Dates_IX_Desc] UNIQUE NONCLUSTERED ([Default_Prompt_Desc] ASC, [Date_Type_Id] ASC)
);

