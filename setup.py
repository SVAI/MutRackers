try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

install_requires = [
    'PyVCF>=0.6.8',
    'keras>=2.0.5',
    'tensorflow>=0.12.0',
    'scikit-learn>=0.18.1'
]

with open('README.md') as f:
    readme = f.read()

setup(
    name='mut-rackers',
    version='1.0.0',
    packages=['model'],
    description='AI Genomics Hackathon project',
    long_description=readme,
    author='Alex Francis',
    author_email='afrancis@berkeley.com',
    install_requires=install_requires,
    classifiers=[
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3.4',
    ]
)
