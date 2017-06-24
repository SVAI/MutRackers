class Featurizer(object):
	"""
	Given a VCF, convert into a valid numpy data matrix which contains
	information about a particular mutation. Also, takes in the "Truth VCF"
	information to construct labels about whether a mutation is both
		(1) Not a false negative.
		(2) Is a "significant variant" (i.e. one that is not present in most
			humans, and has potential to cause disease or other harm).
	"""

	def __init__(self, data_file_name):
		self.data_file_name = data_file_name
        self.data = None # TODO: load the data into RAM.

    def featurize(self):
    	pass
