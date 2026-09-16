import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('stem_worker_contract',Path(__file__).resolve().parents[2]/'runtime/worker/stem_worker.py')
worker=importlib.util.module_from_spec(spec);spec.loader.exec_module(worker)

class MPSProgressContract(unittest.TestCase):
    def test_progress_follows_gpu_synchronization(self):
        order=[]
        original=worker.emit
        worker.emit=lambda kind,**values:order.append((kind,values['completedUnits']))
        try:
            pool=worker.ProgressPool(2,lambda:order.append('synchronize'))
            future=pool.submit(lambda:order.append('inference') or 123)
            self.assertEqual(order,[])
            self.assertEqual(future.result(),123)
            self.assertEqual(order,['inference','synchronize',('progress',1)])
        finally:worker.emit=original

    def test_failed_gpu_synchronization_does_not_advance_progress(self):
        def fail():raise RuntimeError('GPU failure')
        pool=worker.ProgressPool(1,fail)
        with self.assertRaises(RuntimeError):pool.submit(lambda:1).result()
        self.assertEqual(pool.completed,0)
