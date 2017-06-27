-- Find Partition to FileGroup mappings
SELECT
	DestinationId				= DestinationDataSpaces.destination_id ,
	FilegroupName				= Filegroups.name ,
	PartitionHighBoundaryValue	= PartitionRangeValues.value ,
	IsNextUsed					=
		CASE
			WHEN
				DestinationDataSpaces.destination_id > 1
			AND
				LAG (PartitionRangeValues.value , 1) OVER (ORDER BY DestinationDataSpaces.destination_id ASC) IS NULL
			THEN
				1
			ELSE
				0
		END
FROM	sys.partition_schemes AS PartitionSchemes
	INNER JOIN sys.destination_data_spaces AS DestinationDataSpaces ON PartitionSchemes.data_space_id = DestinationDataSpaces.partition_scheme_id
	INNER JOIN sys.filegroups AS Filegroups ON DestinationDataSpaces.data_space_id = Filegroups.data_space_id
	LEFT OUTER JOIN sys.partition_range_values AS PartitionRangeValues ON PartitionSchemes.function_id = PartitionRangeValues.function_id
																		AND DestinationDataSpaces.destination_id = PartitionRangeValues.boundary_id
WHERE	PartitionSchemes.name = N'YourPartitionScheme'
ORDER BY DestinationId ASC;
