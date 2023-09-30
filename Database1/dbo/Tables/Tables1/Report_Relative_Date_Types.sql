CREATE TABLE [dbo].[Report_Relative_Date_Types] (
    [Date_Type_Desc] VARCHAR (50) NOT NULL,
    [Date_Type_Id]   INT          NOT NULL,
    CONSTRAINT [Report_Relative_Date_Types_PK_Id] PRIMARY KEY CLUSTERED ([Date_Type_Id] ASC),
    CONSTRAINT [CReport_Relative_Date_Types_IX_Desc] UNIQUE NONCLUSTERED ([Date_Type_Desc] ASC)
);

