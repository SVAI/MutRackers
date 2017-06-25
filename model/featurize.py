import vcf
import numpy as np
from sklearn import preprocessing

FORMAT_FEATURE_NAMES = ['AD1', 'AD2', 'GQ', 'DP', 'GT']

INFO_FEATURE_NAMES = [
    'ExcessHet', 'AC', 'BaseQRankSum', 'FS', 'AF',
    'MLEAC', 'AN', 'SOR', 'MQ', 'QD', 'DP', 'ClippingRankSum',
    'MQRankSum', 'ReadPosRankSum'
]

OTHER_FEATURE_NAMES = ['QUAL']

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

    def featurize(self):
        with open(self.data_file_name, 'rb') as f:
            vcf_reader_len = vcf.Reader(f)

            num_records = 0
            for record in vcf_reader_len:
                num_records += 1

            f.seek(0)

        data_matrix = np.zeros([
            num_records,
            len(FORMAT_FEATURE_NAMES) + len(INFO_FEATURE_NAMES) + len(OTHER_FEATURE_NAMES)
        ])

        with open(self.data_file_name, 'rb') as f:
            vcf_reader = vcf.Reader(f)

            i = 0
            for record in vcf_reader:
                j = 0
                for info_feature in INFO_FEATURE_NAMES:
                    try:
                        if type(record.INFO[info_feature]) == list:
                            info_feature_value = record.INFO[info_feature][0]
                        else:
                            info_feature_value = record.INFO[info_feature]

                        data_matrix[i][j] = info_feature_value
                        j += 1
                    except KeyError:
                        data_matrix[i][j] = None
                        j += 1

                # This could have also been done using the LabelEncoder in
                # sklearn, but this proved to be somewhat difficult, since
                # you need to add the feature to the matrix as you go, and
                # and the LabelEncoder only works on the final vector. Therefore,
                # I decided to brute force and track the unique string occurrences
                # as I proceed.

                unique_gt = []

                for format_feature in FORMAT_FEATURE_NAMES:
                    format_feature_list = record.samples[0].data
                    if format_feature == 'AD1':
                        format_feature_value = format_feature_list[1][0]
                    elif format_feature == 'AD2':
                        format_feature_value = format_feature_list[1][1]
                    elif format_feature == 'GT':
                        format_feature_value_str = format_feature_list[0]
                        if format_feature_value_str in unique_gt:
                            format_feature_value = unique_gt.index(format_feature_value_str)
                        else:
                            unique_gt.append(format_feature_value_str)
                            format_feature_value = len(unique_gt)
                    elif format_feature == 'DP':
                        format_feature_value = format_feature_list[2]
                    elif format_feature == 'GQ':
                        format_feature_value = format_feature_list[3]

                    data_matrix[i][j] = format_feature_value
                    j += 1

                other_feature_value = record.QUAL
                data_matrix[i][j] = other_feature_value

                i += 1

        imputer = preprocessing.Imputer(strategy='mean')
        imputer.fit(data_matrix)
        data_matrix = imputer.transform(data_matrix)

        return data_matrix
