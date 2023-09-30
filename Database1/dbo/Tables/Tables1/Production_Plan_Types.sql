CREATE TABLE [dbo].[Production_Plan_Types] (
    [PP_Type_Id]   INT          NOT NULL,
    [PP_Type_Name] VARCHAR (25) NOT NULL,
    CONSTRAINT [PK_Production_Plan_Types] PRIMARY KEY CLUSTERED ([PP_Type_Id] ASC),
    CONSTRAINT [Production_Plan_Types_UC] UNIQUE NONCLUSTERED ([PP_Type_Name] ASC)
);

