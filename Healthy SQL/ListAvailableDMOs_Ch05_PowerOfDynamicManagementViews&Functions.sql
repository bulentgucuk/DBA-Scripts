Use master

GO

SELECT [name] ,

CASE [type]

WHEN 'V' THEN 'DMV'

WHEN 'IF' THEN 'DMF'

END AS [DMO Type]

FROM [sys].[sysobjects]

WHERE [name] LIKE 'dm_%'

ORDER BY [name] ; 